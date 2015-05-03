//
//  BatteryServerTest.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/29.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

class BatteryLevelServiceTest:TestBase {
    let l2capFrameFactory = L2CAPFrameFactory()
    let gattServer        = BatteryLevelGATTServer()
    var lastNotifiedAt    = NSDate()
    
    func test() -> () {
        // アドバタイジングを開始します
        var result = _socket.execute_startAdvertisingAndWaitingForConnection()
        if result != .Success {
            println("Fatal error in a connecting.")
            return
        }
        
        while(true) {
            // event
            if let event = _socket.readEventTimeOut() {
                println("event:\(event)")
            }

            // ACL Data
            let (isValid, aclData) = _socket.readACLData()
            if isValid {
                println("\nMaster -> Slave")
                println("ACL Data:\(aclData.simpleDescription())")
                
                // L2CAPの1フレームを取得
                let frame = l2capFrameFactory.parse(aclData.Data)
                if frame == nil {
                    continue;
                }
                let l2capframe = frame!
                // 想定しないチャネルのフレームは無視する
                if(l2capframe.ChannelID == .UnknownChannelID) {
                    continue;
                }
                
                // チャネルごとの処理
                println("L2CAP Frame:\(l2capframe.simpleDescription())")
                switch l2capframe.ChannelID {
                case .AttributeProtocol:
                    let attr = AttributeProtocolPDUFactory.parseAttributeProtocolPDU(l2capframe.InformationPayload)
                    println("Attribute PDU:\(attr.simpleDescription())")
                    
                    if let responseAttr = getATTResponse(attr) {
                        println("\nSlave -> Master")
                        println("Attribute PDU:\(responseAttr.simpleDescription())")
                        let responseL2CAPPDU = l2capFrameFactory.build(.AttributeProtocol, payload: responseAttr.PDU)
                        let responseACLData = HCIACLDataPacket(Handle: aclData.Handle, Packet_Boundary_Flag: .FirstAutomaticallyFlushablePacket, Broadcast_Flag: 0x00, Data:responseL2CAPPDU)
                        println("ACL Data:\(responseACLData.simpleDescription())")
                        _socket.writeACLData(responseACLData)
                    }
                default:
                    println("") // 空行
                }
            }
            
            // Indication / Notification
            
        }
    }
    
    func getATTResponse(attr:AttributeProtocolPDU) -> AttributeProtocolPDU? {
        switch attr.Opcode {
        case .ExchangeMTURequest:
            return AttributeExchangeMTUResponse(ServerRxMTU: 23)
        case .ReadByGroupTypeRequest:
            // GATTサーバに問い合わせる
            let request = attr as! AttributeReadByGroupTypeRequest
            let attrs  = gattServer.readByGroupType(request.StartingHandle, endingHandle:request.EndingHandle, attributeType:request.AttributeType!)
            if attrs.count > 0 {
                let serviceAttr = attrs[0]
                let (startingHandle, endingHandle) = gattServer.getServiceHandleRange(serviceAttr)
                return AttributeReadByGroupTypeResponse(AttributeHandle: startingHandle, EndGroupHandle: endingHandle, AttributeValue: serviceAttr.Value)
            } else {
                return AttributeErrorResponse(requestOpCodeInError: attr.Opcode, attributeHandleInError: request.StartingHandle, errorCode: .AttributeNotFound)
            }
            
        case .ReadByTypeRequest:
            // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part G] page 552
            // Figure 4.5: Discover All Characteristics of a Service example
            let request = attr as! AttributeReadByTypeRequest
            let attrs   = gattServer.readByGroupType(request.StartingHandle, endingHandle:request.EndingHandle, attributeType:request.AttributeType!)
            if attrs.count > 0 {
                let anAttr = attrs[0]
                return AttributeReadByTypeResponse(AttributeHandle: anAttr.Handle, AttributeValue: anAttr.Value)
            } else {
                return AttributeErrorResponse(requestOpCodeInError: attr.Opcode, attributeHandleInError: request.StartingHandle, errorCode: .AttributeNotFound)
            }
        case .ReadRequest:
            // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part F] page 492
            // 3.4.4.3 Read Request
            let request = attr as! AttributeReadRequest
            if let attr   = gattServer.findAttribute(request.AttributeHandle) {
                return AttributeReadResponse(AttributeValue:attr.Value)
            } else {
                return AttributeErrorResponse(requestOpCodeInError: attr.Opcode, attributeHandleInError: request.AttributeHandle, errorCode: .InvalidHandle)
            }
            
        default:
            return nil
        }
    }
}
