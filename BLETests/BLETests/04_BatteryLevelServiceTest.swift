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
            
            // Custom service
            PrimaryServiceAttribute(handle: 0x0020, uuid:BleUUID(uuid: "00C5E2A5-545A-4402-862E-EAA09D4C04D1")),
            CharacteristicDeclarationAttribute(handle: 0x0021, properties: [.Indicate], valueHandle: 0x0022, uuid: BleUUID(uuid:"01C5E2A5-545A-4402-862E-EAA09D4C04D1")),
            CharacteristicValueDeclarationAttribute(handle: 0x0022, characteristicUUID: BleUUID(uuid:"01C5E2A5-545A-4402-862E-EAA09D4C04D1"), value: [0x00]),
            CharactristicPresentationFormatAttribute(handle: 0x0023,
                format: 0x04, // unsigned int8
                exponent: 0,
                unit: 0x27ad, //0x27AD	percentage	org.bluetooth.unit.percentage, see https://developer.bluetooth.org/gatt/units/Pages/default.aspx
                nameSpace: 0x01, // Bluetooth SIG Assigned Numbers
                description: 0x00),
            ClientCharactristicConfigurationAttribute(handle: 0x0024, CharacteristicConfigurations: []),
        ]
    }
}

class BatteryLevelServiceTest:TestBase {
    let l2capFrameFactory = L2CAPFrameFactory()
    let gattServer        = BatteryLevelGATTServer()
    
    var lastNotifiedAt    = NSDate()
    
    let queue     = dispatch_queue_create("BLETest", DISPATCH_QUEUE_CONCURRENT)
    
    var isConnected = true
    var handle:UInt16 = 0
    
    // Indicationのトランザクション実行中フラグ
    var proceedingIndicationTransaction = false
    
    override func test() -> () {
        
        // アドバタイジングを開始します
        var result = _socket.execute_startAdvertisingAndWaitingForConnection()
        if result != .Success {
            println("Fatal error in a connecting.")
            return
        }
        self.isConnected = true
        
        // コマンドの受信処理
        dispatch_async(queue) {
            while(true) {
                if let event = self._socket.readEvent() {                    
                    self.synchronized(self) {
                        println("\nevent:\(event.simpleDescription())")
                        if event.eventCode == .DisconnectionComplete {
                            self.isConnected = false
                        }
                    }
                }
            }
        }
        
        // ATTの処理
        dispatch_async(queue) {
            while(true) {
                let aclData = self._socket.readACLData()
                
                self.synchronized(self) {
                    if aclData != nil {
                        self.handle = aclData!.Handle
                        
                        println("\nMaster -> Slave")
                        println("ACL Data:\(aclData!.simpleDescription())")
                        
                        // L2CAPの1フレームを取得
                        let frame = self.l2capFrameFactory.parse(aclData!.Data)
                        if frame == nil {
                            return // closureで呼び出しているので, returnで帰る
                        }
                        let l2capframe = frame!
                        // 想定しないチャネルのフレームは無視する
                        if(l2capframe.ChannelID == .UnknownChannelID) {
                            println("Unknonw l2cap channel ID")
                            return // closureで呼び出しているので, returnで帰る
                        }
                        
                        // チャネルごとの処理
                        println("L2CAP Frame:\(l2capframe.simpleDescription())")
                        switch l2capframe.ChannelID {
                        case .AttributeProtocol:
                            let attr = AttributeProtocolPDUFactory.parseAttributeProtocolPDU(l2capframe.InformationPayload)
                            println("Attribute PDU:\(attr.simpleDescription())")
                            
                            if let responseAttr = self.getATTResponse(attr) {
                                println("\nSlave -> Master")
                                println("Attribute PDU:\(responseAttr.simpleDescription())")
                                let responseL2CAPPDU = self.l2capFrameFactory.build(.AttributeProtocol, payload: responseAttr.PDU)
                                let responseACLData = HCIACLDataPacket(Handle: aclData!.Handle, Packet_Boundary_Flag: .FirstAutomaticallyFlushablePacket, Broadcast_Flag: 0x00, Data:responseL2CAPPDU)
                                println("ACL Data:\(responseACLData.simpleDescription())")
                                self._socket.writeACLData(responseACLData)
                            }
                            
                            // Indicationのトランザクション終了処理
                            if attr is HandleValueConfirmation {
                                self.proceedingIndicationTransaction = false
                            }
                            
                        default:
                            println("") // 空行
                        }
                    }
                }
            }
        }
        
        // ノーティフィケーションを飛ばす
        dispatch_async(queue) {
            // バッテリサービスのバッテリ値のCCCDを取得します
            let batteryLevelValueDeclarationAttribute = self.gattServer.findAttribute(0x0012) as! CharacteristicValueDeclarationAttribute
            let cccd  = self.gattServer.findAttribute(0x0014) as! ClientCharactristicConfigurationAttribute
            
            while true {
                if cccd.CharacteristicConfigurations.count > 0 && cccd.CharacteristicConfigurations[0] == .Notification {
                    
                    self.synchronized(self) {
                        // バッテリ値を -1 する
                        var batteryLevel = batteryLevelValueDeclarationAttribute.Value[0]
                        batteryLevel = (batteryLevel - 1 + 100) % 100
                        batteryLevelValueDeclarationAttribute.Value = [batteryLevel]
                        
                        println("\nSlave -> Master (notification)")
                        var notification = HandleValueNotification(attributeHandle: 0x012, attributeValue: [batteryLevel])
                        println("Attribute PDU:\(notification.simpleDescription())")
                        let responseL2CAPPDU = self.l2capFrameFactory.build(.AttributeProtocol, payload: notification.PDU)
                        let responseACLData = HCIACLDataPacket(Handle:self.handle, Packet_Boundary_Flag: .FirstAutomaticallyFlushablePacket, Broadcast_Flag: 0x00, Data:responseL2CAPPDU)
                        println("ACL Data:\(responseACLData.simpleDescription())")
                        self._socket.writeACLData(responseACLData)
                    }
                }
                
                sleep(1)
            }
        }
        
        // カスタムサービスのIndicationを行う
        dispatch_async(queue) {
            let characteristicsValue = self.gattServer.findAttribute(0x0022) as! CharacteristicValueDeclarationAttribute
            let cccd                 = self.gattServer.findAttribute(0x0024) as! ClientCharactristicConfigurationAttribute
            
            while true {
                if !self.proceedingIndicationTransaction && cccd.CharacteristicConfigurations.count > 0 && cccd.CharacteristicConfigurations[0] == .Indication {
                    self.synchronized(self) {
                        // 値を+1する
                        var val = characteristicsValue.Value[0]
                        val = (val + 1) % 100
                        characteristicsValue.Value = [val]
                        
                        println("\nSlave -> Master (indication)")
                        var notification = HandleValueIndication(attributeHandle: 0x022, attributeValue: [val])
                        println("Attribute PDU:\(notification.simpleDescription())")
                        let responseL2CAPPDU = self.l2capFrameFactory.build(.AttributeProtocol, payload: notification.PDU)
                        let responseACLData = HCIACLDataPacket(Handle:self.handle, Packet_Boundary_Flag: .FirstAutomaticallyFlushablePacket, Broadcast_Flag: 0x00, Data:responseL2CAPPDU)
                        println("ACL Data:\(responseACLData.simpleDescription())")
                        self._socket.writeACLData(responseACLData)
                        
                        // トランザクションを開始
                        self.proceedingIndicationTransaction = true
                    }
                }
                sleep(1)
            }
        }
        
        // 切断を待つ
        while self.isConnected {
            usleep(10000)
        }
        println("\nDisconnected")
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
