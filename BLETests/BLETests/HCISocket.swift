//
//  HCISocket.swift
//  testusb
//
//  Created by AkihiroUehara on 2015/04/07.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// HCIのコマンド/イベントのやりとりの詳細を隠ぺいするクラスです

class HCISocket {
    var PeerAddressType:UInt8 = 0
    var PeerAddress:[UInt8] = []
    var OwnAddressType:UInt8  = 0x00
    var OwnAddress:[UInt8]    = []
    
    var ConnectionHandle:UInt16 = 0
    
    // MARK: Variables
    let _adaptor:BluetoothUSBAdaptor
    
    // MARK: constructor
    init(adaptor:BluetoothUSBAdaptor) {
        _adaptor = adaptor
    }
    
    func readEvent() -> HCIEvent? {
        let data = _adaptor.readHCIEvent()
        if data.length == 0 {
            return nil
        }
        
        var buffer = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&buffer, length:data.length)
        //println("packet:\(packet) buffer:\(buffer)")
        let event = HCIEventParser.parse(buffer)
        
        return event
    }
    
    func sendCommand(command:HCIOpcodeCommand, parameters:[UInt8]) -> (HCIEvent){
        // コマンドパケットを構築する。
        //
        // HCIコマンドパケットは、先頭2オクテットのおペーコード、それにパラメータのオクテット数を表す1オクテットの値、パラメータが続きます。
        // 0           9     16             24          32          40
        // +--------+--------+--------------+-----------+-----------+--
        // | OpCode          | Parameter    |Parameter0 |Parameter1 | ...
        // +-----------------+ Total Length |           |           |
        // | OCF      | OGF  |              |           |           |
        // +--------+--------+--------------+-----------+-----------+---
        // OCF:OpCode Command Field
        // OGF OpCode Group Field
        //
        // BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 471
        // Figure 5.1: HCI Command Packet
        //
        let OpcodeGroupField   = UInt8(command.rawValue >> 16)
        let OpCodeCommandFiled = UInt16(command.rawValue & 0x0000ffff)
        
        var packet = [UInt8](count:(2+1), repeatedValue:0)
        packet[0] = UInt8(0x00ff & OpCodeCommandFiled)
        packet[1] = UInt8(OpcodeGroupField << 2) | UInt8(OpCodeCommandFiled >> 8)
        packet[2] = UInt8(parameters.count)
        packet += parameters
        
        let data   = _adaptor.executeCommand(NSData(bytes:&packet, length:packet.count * sizeof(UInt8)))
        var buffer = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&buffer, length:data.length)
        //println("packet:\(packet) buffer:\(buffer)")
        
        return HCIEventParser.parse(buffer)
    }
    
    func readACLData() -> (HCIACLDataPacket?) {
        let data = _adaptor.readACLData();
        var buffer = [UInt8](count:data.length, repeatedValue:0)
        data.getBytes(&buffer, length:data.length)
        if data.length != 0 {
            return HCIACLDataPacket(packet:buffer)
        } else {
            return nil
        }
    }
    
    func writeACLData(data:HCIACLDataPacket) -> (Bool) {
        var pdu = data.PDU
        return _adaptor.writeACLData(NSData(bytes:&pdu, length:pdu.count))
    }
    
    // MARK:HCIのコマンド実行のヘルパー
    
    func execute_Reset() -> (HCIEvent) {
        return self.sendCommand(.Reset, parameters:[])
    }
    
    // ローカルの情報をprintlnします
    func print_localInformation() {
        var event = self.sendCommand(.ReadLocalVersionInformation, parameters:[])
        if event.eventCode != .CommandCompleted {
            return
        }
        println("Local version information:"
            + String(format:"\n\t HCI_Version:%d", event.parameters[1])
            + String(format:"\n\t HCI_Revision:%d", UInt16(event.parameters[2]) | UInt16(event.parameters[3]) << 8 )
            + String(format:"\n\t ManufacturerName:0x%04x", UInt16(event.parameters[5]) | UInt16(event.parameters[6]) << 8 )
        )
        
        event = self.sendCommand(.ReadBufferSize, parameters:[])
        if event.eventCode != .CommandCompleted {
            return
        }
        println("Buffer size:"
            + String(format:"\n\t HCI_ACL_Data_Packet_Length:%d",     UInt16(event.parameters[1]) | UInt16(event.parameters[2]) << 8 )
            + String(format:"\n\t HCI_Total_Num_ACL_Data_Packets:%d", UInt16(event.parameters[4]) | UInt16(event.parameters[5]) << 8 )
        )
    }
    
    // BD_ADDRを読み出します。アドレス配列は内部でエンディアンを変換して、ビッグエンディアンにして返します。
    func execute_ReadBD_ADDR() -> (errorCode: HCIErrorCode, BD_ADDR:[UInt8]) {
        let event = self.sendCommand(.ReadBD_ADDR, parameters:[])
        if event.eventCode != .CommandCompleted {
            // コマンド自体が完了できなかった
            return (.UnknownHCICommand, event.parameters)
        } else {
            // アドレス値を構成。リトルエンジェルなので、バイト配列を並び替える
            let commandCompletedEvent = event as! HCIEventCommandComplete
            return (HCIErrorCode(rawValue: commandCompletedEvent.Return_Parameters[0])!, [UInt8](commandCompletedEvent.Return_Parameters[1...6].reverse()))
        }
    }
    
    func execute_setMetaEventMask() ->(HCIErrorCode) {
        //イベントマスクを設定
        // 0x00 00 1F FF FF FF FF FF Default
        //(0x2000000000000000 LE Meta-Event)
        var event = self.sendCommand(.SetEventMask, parameters:[0xff, 0xff, 0xff, 0xff, 0xff, 0x1f, 0x00, 0x20 ])
        // コマンド自体が完了できなかった
        if event.eventCode != .CommandCompleted {
            return .UnknownHCICommand
        }
        // エラーコードをチェック。Successでなければ、返す。
        var commandCompletedEvent = event as! HCIEventCommandComplete
        var errorCode = HCIErrorCode(rawValue: commandCompletedEvent.Return_Parameters[0])!
        if errorCode != .Success {
            return errorCode
        }
        
        // LEメタイベントを設定
        //0x000000000000001F Default
        event = self.sendCommand(.LESetEventMask, parameters:[0x1F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ])
        // コマンド自体が完了できなかった
        if event.eventCode != .CommandCompleted {
            return .UnknownHCICommand
        }
        // コマンド実行結果を返す
        commandCompletedEvent = event as! HCIEventCommandComplete
        errorCode = HCIErrorCode(rawValue: commandCompletedEvent.Return_Parameters[0])!
        return errorCode
    }
    
    func execute_startAdvertising()-> HCIErrorCode {
        var result:HCIErrorCode
        var event:HCIEvent
        var eventCode:HCIEventCode
        var BD_ADDR:[UInt8]
        
        event = self.execute_Reset()
        if event.eventCode != .CommandCompleted {
            return HCIErrorCode.UnknownHCICommand
        }
        
//        self.print_localInformation()
        
        (result, BD_ADDR) = self.execute_ReadBD_ADDR()
        if result != .Success {
            return result
        }
        
        // ローカルのアドレスタイプとアドレスを保存します
        self.OwnAddressType = 0x00 // 0x00: public address
        self.OwnAddress     = BD_ADDR
        
        result = execute_setMetaEventMask()
        if result != .Success {
            return result
        }
        
        // アドバタイジングを開始する
        event = self.sendCommand(.LESetAdvertisingData, parameters:[
            // 一般的なアドバタイジング・データの例。
            0x10, // Advertising_Data_Length, 3 + 9 + 4 = 16
            
            // Advertising dataのフォーマット:
            // Length(1), AD type(1), AD Data(length -1)
            
            // AD type Flags(0x01), 0x01 | 0x02
            //  LE General Discoverable Mode 0x01
            //  BR/EDR Not Supported         0x02
            0x02, 0x01, 0x03,
            
            // Shortened Local Name (0x08), Complete Local Name (0x09)
            // ここではShortened Local Name
            //  UTF-8 text (TESTDEV)
            0x08, 0x08, 0x54, 0x45, 0x53, 0x54, 0x44, 0x45, 0x56,
            
            // Incomplete List of 16-bit Service Class UUIDs (0x02)
            //  UUID 0x12, 0x34
            0x03, 0x02, 0x12, 0x34,
            
            // 31オクテットにするための埋草
            // 31 - 16 = 15
            0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00
            ])
        if event.eventCode != .CommandCompleted {
            println("Fatal error in LESetAdvertisingData.")
            return HCIErrorCode(rawValue: event.parameters[0])!
        }
        
        event = self.sendCommand(.LESetAdvertisingParameters, parameters:[
            0x30, 0x00, //Addvertisiong_Interval_Min:    0x0030 (30ミリ秒)
            0x00, 0x08, // Advertising_Interval_Max:     0x0800 (1.28sec)
            0x00, // Advertisiong_type: 0x00 Connectable undirected advertisiong ADV_IND
            
            0x00, // Own_Address_type:  Public Device Address (default)
            0x00, // Peer_Address_type: Public Device Address
            
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Peer_adddress
            
            // Advertising_Channel_Map:
            0x01,     // アドバタイジングチャネルを37のみに固定する。
            //0x07,   //すべてのチャネルでアドバタイジングする。
            
            0x00  // Advertisiong_Filter_Policy: Process scan and connection requests from all devices.
            ])
        if event.eventCode != .CommandCompleted {
            println("Fatal error in LESetAdvertisingParameters.")
            return HCIErrorCode(rawValue: event.parameters[0])!
        }
        
        event = self.sendCommand(.LESetAdvertiseEnable, parameters: [0x01])
        if event.eventCode != .CommandCompleted {
            println("Fatal error in LESetAdvertiseEnable")
            return HCIErrorCode(rawValue: event.parameters[0])!
        }
        
        return HCIErrorCode.Success
    }
    
    func execute_startAdvertisingAndWaitingForConnection() -> HCIErrorCode {
        // アドバタイジングを実行します
        var result = self.execute_startAdvertising()
        if result != .Success {
            println("Fatal error in starting an advertisement.")
            return result
        } else {
            println("== Advertising ==")
        }
        
        // 接続完了を待ちます。
        while(true) {
            if let connectionCompletedEvent = self.readEvent() as? HCIEventLEConnectionComplete {
                self.PeerAddressType = connectionCompletedEvent.Peer_Address_Type
                self.PeerAddress     = connectionCompletedEvent.Peer_Address
                self.ConnectionHandle = connectionCompletedEvent.Connection_Handle
                break
            }
        }
        
        return .Success
    }

    func execute_longTermKeyRequestNegativeReply() -> HCIErrorCode {
        var result:HCIErrorCode
        var event:HCIEvent
        var eventCode:HCIEventCode
        
        var handle = [UInt8](count:2, repeatedValue:0)
        handle[0] = UInt8(ConnectionHandle & 0x00ff)
        handle[1] = UInt8(ConnectionHandle >> 8)
        event = self.sendCommand( .LELongTermKeyRequestNegativeReply, parameters: handle)
       
        println("\nHost -> Controller\n command:.LELongTermKeyRequestNegativeReply parameters:\(handle)")
        println("\nController -> Host \n event:\(event)")
        
        if event.eventCode != .CommandCompleted {
            println("Fatal error in LELongTermKeyRequestNegativeReply.")
            return HCIErrorCode(rawValue: event.parameters[0])!
        }
        
        return HCIErrorCode.Success
    }
    
    func execute_longTermKeyRequestReply(longTermKey:[UInt8])-> HCIErrorCode {
        var result:HCIErrorCode
        var event:HCIEvent
        var eventCode:HCIEventCode
        
        var handle = [UInt8](count:2, repeatedValue:0)
        handle[0]  = UInt8(ConnectionHandle & 0x00ff)
        handle[1]  = UInt8(ConnectionHandle >> 8)
        event = self.sendCommand( .LELongTermKeyRequestReply, parameters: handle + longTermKey.reverse())
        
        println("\nHost -> Controller\n command:.LELongTermKeyRequestReply parameters:\(handle + longTermKey.reverse())")
        println("\nController -> Host \n event:\(event)")
        
        if event.eventCode != .CommandCompleted {
            println("Fatal error in LELongTermKeyRequestReply.")
            return HCIErrorCode(rawValue: event.parameters[0])!
        }
        
        return HCIErrorCode.Success
    }
}