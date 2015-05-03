//
//  L2CAPSocket.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/23.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// L2CAPの詳細を隠ぺいするクラスです

class L2CAPSocket {
    // MARK: Variables
    let _socket:HCISocket
    
    // MARK: constructor
    init(socket:HCISocket) {
        _socket = socket
    }
    
    // MARK:private methods
    
    // MARK:public methods
    /*
    func readEvent() -> (HCIEvent) {
        let data = _adaptor.readHCIEvent()
        var buffer = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&buffer, length:data.length)
        //println("packet:\(packet) buffer:\(buffer)")
        return HCIEventParser.parse(buffer)
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
        
        packet = [UInt8](count:(2+1), repeatedValue:0)
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
    */
}

