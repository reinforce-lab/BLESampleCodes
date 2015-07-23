//
//  ParingAndBondingTest.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/05/06.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation


class CustomGATTServer:SimpleGATTServer {
    override init() {
        super.init()
        self.Database += [
            PrimaryServiceAttribute(handle: 0x0030, uuid:BleUUID(uuid: "003F40E9-DA6C-47E8-9D14-3680A4AB84A3")),
            CharacteristicDeclarationAttribute(handle: 0x0031, properties: [.Read], valueHandle: 0x0032, uuid: BleUUID(uuid:"013F40E9-DA6C-47E8-9D14-3680A4AB84A3")),
            CharacteristicValueDeclarationAttribute(handle: 0x0032, characteristicUUID: BleUUID(uuid:"013F40E9-DA6C-47E8-9D14-3680A4AB84A3"), value: [0x00]),
            CharactristicPresentationFormatAttribute(handle: 0x0033,
                format: 0x04, // unsigned int8
                exponent: 0,
                unit: 0x27ad,    //0x27AD	percentage	org.bluetooth.unit.percentage, see https://developer.bluetooth.org/gatt/units/Pages/default.aspx
                nameSpace: 0x01, // Bluetooth SIG Assigned Numbers
                description: 0x00),
            ClientCharactristicConfigurationAttribute(handle: 0x0034, CharacteristicConfigurations: []),
            /*
            CharacteristicDeclarationAttribute(handle: 0x0041, properties: [.Read, .AuthenticatedSignedWrites], valueHandle: 0x0042, uuid: BleUUID(uuid:"023F40E9-DA6C-47E8-9D14-3680A4AB84A3")),
            CharacteristicValueDeclarationAttribute(handle: 0x0042, characteristicUUID: BleUUID(uuid:"023F40E9-DA6C-47E8-9D14-3680A4AB84A3"), value: [0x00]),
            CharactristicPresentationFormatAttribute(handle: 0x0043,
                format: 0x04, // unsigned int8
                exponent: 0,
                unit: 0x27ad, //0x27AD	percentage	org.bluetooth.unit.percentage, see https://developer.bluetooth.org/gatt/units/Pages/default.aspx
                nameSpace: 0x01, // Bluetooth SIG Assigned Numbers
                description: 0x00),
            ClientCharactristicConfigurationAttribute(handle: 0x0044, CharacteristicConfigurations: []),
*/
        ]
    }
}

class ParingTest:TestBase {
    let l2capFrameFactory = L2CAPFrameFactory()
    let gattServer        = CustomGATTServer()
    let securityManager   = SecurityManager()
    
    var lastNotifiedAt    = NSDate()
    
    let queue     = dispatch_queue_create("BLETest", DISPATCH_QUEUE_CONCURRENT)

    var isConnected = true
    var handle:UInt16 = 0
    
    // Indicationのトランザクション実行中フラグ
    var proceedingIndicationTransaction = false
    
    var longTermKey:[UInt8] = []
    
    override func test() -> () {
        
        // アドバタイジングを開始します
        var result = _socket.execute_startAdvertisingAndWaitingForConnection()
        if result != .Success {
            println("Fatal error in a connecting.")
            return
        }
        self.isConnected = true
        
        // デバイスのアドレス情報をセキュリティマネージャに保存します
        self.securityManager.initiatorAddressType = _socket.PeerAddressType
        self.securityManager.initiatorAddress     = _socket.PeerAddress
        self.securityManager.respondingDeviceAddressType = _socket.OwnAddressType
        self.securityManager.respondingDeviceAddress = _socket.OwnAddress
        
        // コマンドの受信処理
        dispatch_async(queue) {
            while(true) {
                if let event = self._socket.readEvent() {
                    self.synchronized(self) {
                        // TODO ここのコード、綺麗に書きなおすこと
                        if let numOfCompletedPacketEvent = event as? HCIEventNumberOfCompletedPackets {
                        } else {
                            
                        println("\nController -> Host\nevent:\(event.simpleDescription())")
                        if let longTermKeyRequest = event as? HCIEventLELongTermKeyRequestEvent {
                            // Long term key がなければ、short time keyを発行する
                            let key = (self.longTermKey.count > 0) ? self.longTermKey : self.securityManager.getShortTermKey()
                            self._socket.execute_longTermKeyRequestReply(key)
/*
                            self._socket.execute_longTermKeyRequestNegativeReply()
*/
                        }
                        if let encryptionChange = event as? HCIEventEncryptionChange {
                            println("\(encryptionChange)")

                            self.distributekeys()
                        }
                        if event.eventCode == .DisconnectionComplete {
                            self.isConnected = false
                        }
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
                        
//                        println("\nMaster -> Slave")
//                        println("ACL Data:\(aclData!.simpleDescription())")
                        
                        // L2CAPの1フレームを取得
                        let frame = self.l2capFrameFactory.parse(aclData!.Data)
                        if frame == nil {
                            return // closureで呼び出しているので, returnで帰る
                        }
                        let l2capframe = frame!
                        // 想定しないチャネルのフレームは無視する
                        if(l2capframe.ChannelID == .UnknownChannelID) {
//                            println("Unknonw l2cap channel ID")
                            return // closureで呼び出しているので, returnで帰る
                        }
                        
                        // チャネルごとの処理
//                        println("L2CAP Frame:\(l2capframe.simpleDescription())")
                        
                        println("\nMaster -> Slave")
                        
                        switch l2capframe.ChannelID {
                        case .AttributeProtocol:
                            let attr = AttributeProtocolPDUFactory.parseAttributeProtocolPDU(l2capframe.InformationPayload)
                            println("Attribute PDU:\(attr.simpleDescription())")
                            
                            if let responseAttr = self.getATTResponse(attr) {
                                println("\nSlave -> Master")
                                println("Attribute PDU:\(responseAttr.simpleDescription())")
                                let responseL2CAPPDU = self.l2capFrameFactory.build(.AttributeProtocol, payload: responseAttr.PDU)
                                let responseACLData = HCIACLDataPacket(Handle: aclData!.Handle, Packet_Boundary_Flag: .FirstAutomaticallyFlushablePacket, Broadcast_Flag: 0x00, Data:responseL2CAPPDU)
//                                println("ACL Data:\(responseACLData.simpleDescription())")
                                self._socket.writeACLData(responseACLData)
                            }
                            
                            // Indicationのトランザクション終了処理
                            if attr is HandleValueConfirmation {
                                self.proceedingIndicationTransaction = false
                            }
                        case .SecurityManagerProtocol: // ChannelID 0x06
                            let smp = SecurityManagerProtocolPDUFactory.parseSecurityManagerProtocolPDU(l2capframe.InformationPayload)
                            println("SecureManagement PDU:\(smp.simpleDescription())")
                            
                            if let response = self.getSecurityManagerResponse(smp) {
                                println("\nSlave -> Master")
                                println("Security manager:\(response.simpleDescription())")
                                let responseL2CAPPDU = self.l2capFrameFactory.build(.SecurityManagerProtocol, payload: response.PDU)
                                let responseACLData = HCIACLDataPacket(Handle: aclData!.Handle, Packet_Boundary_Flag: .FirstAutomaticallyFlushablePacket, Broadcast_Flag: 0x00, Data:responseL2CAPPDU)
//                                println("ACL Data:\(responseACLData.simpleDescription())")
                                self._socket.writeACLData(responseACLData)
                            }
                            // 返信
                        default:
                            println("") // 空行
                        }
                    }
                }
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
                if self.longTermKey.count > 0 {
                    return AttributeReadResponse(AttributeValue:foundAttribute.Value)
                } else {
                    // insufficient authentication を返す
                    // Authentication(認証)は、本人確認。Authorization(認可)は、権限の付与。
                    return AttributeErrorResponse(requestOpCodeInError: attr.Opcode, attributeHandleInError: request.AttributeHandle, errorCode: .InsufficientAuthentication)
                }
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

    // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 660
    // Security Manager Specification
    // APPENDIX C MESSAGE SEQUENCE CHARTS
    func getSecurityManagerResponse(smp:SecurityManagerProtocolPDU) -> SecurityManagerProtocolPDU? {
        switch smp.Code {
        case .PairingRequest:
            let response = PairingResponse(IOCapability: .NoInputNoOutput, OOBDataFlag: .OOBAuthenticationDataNotPresent,
                /* BondingFlags:true, */
                BondingFlags:false,
                MITM:true, SC:false, Keypress:false,
                MaximumEncryptionKeySize: 16, InitiatorKeyDistribution: 0x03, /*ResponderKeyDistribution: 0x03 */ ResponderKeyDistribution: 0x01 )
            
            self.securityManager.pairingRequest  = smp as? PairingRequest
            self.securityManager.pairingResponse = response

            return response
            
        case .PairingConfirm:
            self.securityManager.mPairingConfirm = (smp as! PairingConfirm).ConfirmValue
            let confirmValue = self.securityManager.getSConfirmValue()
            let response     = PairingConfirm(confirmValue: confirmValue)
            
            return response
            
        case .PairingRandom:
            let pairingRandom = smp as! PairingRandom
            self.securityManager.mPairingRandom = pairingRandom.RandomValue

            // confirm valueの確認
            self.securityManager.isValidMConfirmValue(securityManager.mPairingConfirm, pairingRandom:securityManager.mPairingRandom)

            // response
            let response = PairingRandom(randomValue: self.securityManager.sPairingRandom)
            return response
            
        default: return nil
        }
    }

    // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 678
    // C.3 PHASE 3: TRANSPORT SPECIFIC KEY DISTRIBUTION
    func distributekeys() {
        println("Security manager, disributing keys\n  Slave -> Master")
        
        let longTermKey = self.securityManager.getLongTermKey([0x00, 0x00])
        self.longTermKey = longTermKey
        
        let encryptionInformation = EncryptionInformation(longTermKey: longTermKey)
        self.sendSeuciryManagerPDU(encryptionInformation)
        
        let div:[UInt8]  = [0x11, 0x12]
        let rand:[UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
        let ediv = self.securityManager.getEDIV(div, rand: rand)
        let masterIndication = MasterIdentification(EDIV:ediv, rand:rand)
        self.sendSeuciryManagerPDU(masterIndication)
    }
    
    func sendSeuciryManagerPDU(pdu:SecurityManagerProtocolPDU) {
        println("\(pdu.simpleDescription())")
        let l2capPDU = self.l2capFrameFactory.build(.SecurityManagerProtocol, payload: pdu.PDU)
        let aclData  = HCIACLDataPacket(Handle: self.handle, Packet_Boundary_Flag: .FirstAutomaticallyFlushablePacket, Broadcast_Flag: 0x00, Data:l2capPDU)
        self._socket.writeACLData(aclData)
    }
}
