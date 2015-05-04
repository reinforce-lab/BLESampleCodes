//
//  BatteryServerTest.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/29.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// バッテリーレベルのサービスをもつGATTサーバ
class BatteryLevelGATTServer:SimpleGATTServer {
    override init() {
        super.init()
        self.Database += [
            // Battery level
            // https://developer.bluetooth.org/gatt/services/Pages/ServiceViewer.aspx?u=org.bluetooth.service.battery_service.xml
            PrimaryServiceAttribute(handle: 0x0010, uuid:BleUUID(bluetoothUUID: 0x180F)),
            // Battery level
            CharacteristicDeclarationAttribute(handle: 0x0011, properties:[.Read, .Notify], valueHandle: 0x0012, uuid: BleUUID(bluetoothUUID: 0x2a19)),
            CharacteristicValueDeclarationAttribute(handle:  0x0012, characteristicUUID: BleUUID(bluetoothUUID: 0x2a19), value:[UInt8(100)] ),
            CharactristicPresentationFormatAttribute(handle: 0x0013,
                format: 0x04,    // unsigned int8
                exponent: 0,
                unit: 0x27ad,    //0x27AD	percentage	org.bluetooth.unit.percentage, see https://developer.bluetooth.org/gatt/units/Pages/default.aspx
                nameSpace: 0x01, // Bluetooth SIG Assigned Numbers
                description: 0x00),
            ClientCharactristicConfigurationAttribute(handle: 0x0014, CharacteristicConfigurations: []),
        ]
    }
}

class BatteryLevelServiceTest:TestBase {
    let l2capFrameFactory = L2CAPFrameFactory()
    let gattServer        = BatteryLevelGATTServer()
    var lastNotifiedAt    = NSDate()
    var batteryLevel:UInt8 = 100
    
    func test() -> () {
        // アドバタイジングを開始します
        var result = _socket.execute_startAdvertisingAndWaitingForConnection()
        if result != .Success {
            println("Fatal error in a connecting.")
            return
        }
        
        // バッテリサービスのバッテリ値のCCCDを取得します
        let batteryLevelValueDeclarationAttribute = gattServer.findAttribute(0x0012) as! CharacteristicValueDeclarationAttribute
        let cccd  = gattServer.findAttribute(0x0014) as! ClientCharactristicConfigurationAttribute
        
        while(true) {
            // event
            if let event = _socket.readEventTimeOut() {
                println("\nevent:\(event.simpleDescription())")
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
            if cccd.CharacteristicConfigurations.count > 0 && cccd.CharacteristicConfigurations[0] == .Notification && abs(lastNotifiedAt.timeIntervalSinceNow) > 1.0 {
                println("\nSlave -> Master (notification)")
                lastNotifiedAt = NSDate()
                batteryLevel = (batteryLevel - 1 + 100) % 100
                var notification = HandleValueNotification(attributeHandle: 0x012, attributeValue: [batteryLevel])
                println("Attribute PDU:\(notification.simpleDescription())")
                let responseL2CAPPDU = l2capFrameFactory.build(.AttributeProtocol, payload: notification.PDU)
                let responseACLData = HCIACLDataPacket(Handle: aclData.Handle, Packet_Boundary_Flag: .FirstAutomaticallyFlushablePacket, Broadcast_Flag: 0x00, Data:responseL2CAPPDU)
                println("ACL Data:\(responseACLData.simpleDescription())")
                _socket.writeACLData(responseACLData)
            }
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
                let foundAttribute = attrs[0]
                return AttributeReadByTypeResponse(AttributeHandle: foundAttribute.Handle, AttributeValue: foundAttribute.Value)
            } else {
                return AttributeErrorResponse(requestOpCodeInError: attr.Opcode, attributeHandleInError: request.StartingHandle, errorCode: .AttributeNotFound)
            }

        case .ReadRequest:
            // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part F] page 492
            // 3.4.4.3 Read Request
            let request = attr as! AttributeReadRequest
            if let foundAttribute   = gattServer.findAttribute(request.AttributeHandle) {
                return AttributeReadResponse(AttributeValue:foundAttribute.Value)
            } else {
                return AttributeErrorResponse(requestOpCodeInError: attr.Opcode, attributeHandleInError: request.AttributeHandle, errorCode: .InvalidHandle)
            }

        case .FindInformationRequest:
            // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part F] page 485
            // 3.4.3.1 Find Information Request
            let request = attr as! AttributeFindInformationRequest
            let attrs = gattServer.findAttributes(request.StartingHandle, endingHandle:request.EndingHandle)
            if attrs.count > 0 {
                let foundAttr = attrs[0]
                var data = [UInt8](count:2, repeatedValue:0)
                data[0] = UInt8(foundAttr.Handle & 0x00ff)
                data[1] = UInt8(foundAttr.Handle >> 8)
                data += foundAttr.Type!.Bytes.reverse() // LSB-firstなので反転します
                return AttributeFindInformationResponse(Format: (foundAttr.Type!.IsBluetoothUUID) ? .HandlesAnd16bitUUIDs : .HandlesAnd128bitUUIDs, InformationData:data)
            } else {
                return AttributeErrorResponse(requestOpCodeInError: attr.Opcode, attributeHandleInError:request.StartingHandle , errorCode: .AttributeNotFound)
            }

        case .WriteRequest:
            // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part F] page 499
            // 3.4.5.1 Write Request
            let request = attr as! AttributeWriteRequest
            if let foundAttribute = gattServer.findAttribute(request.AttributeHandle) {
                foundAttribute.Value = request.AttributeValue
                return AttributeWriteResponse()
            } else {
                return AttributeErrorResponse(requestOpCodeInError: attr.Opcode, attributeHandleInError:request.AttributeHandle , errorCode: .InvalidHandle)
            }
            
        default:
            return nil
        }
    }
}
