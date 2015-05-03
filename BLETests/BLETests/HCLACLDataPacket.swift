//
//  HCLACLDataPacket.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/23.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

//
// BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 472
// 5.4.2 HCI ACL Data Packets
// HCIイベントパケットは、先頭1オクテットのイベントコード、それにパラメータのオクテット数を表す1オクテットの値、パラメータが続きます。
//
// 0                 12     14     16                  31               (bits)
// +-----------------+------+------+-------------------+-----------+
// | Handle          | PB   | BC   | Data Total Length | Data      |
// |                 | Flag | Flag |                   |           |
// +-----------------+------+------+-------------------+-----------+
//
//
// Packet_Boundary_Flag (PB Flag)
//                           LE-U
// 00b  
// First non-automatically-flushable packet of Higher Layer Message from Host to Controller.
//      Host to Controller:  allowed
//      Controller to Host:  not allowd
// 01b
// Continuing fragment of Higher Layer Message.
//      Host to Controller:  allowed
//      Controller to Host:  allowed
// 10b
// First automatically flushable packet of Higher Layer Message.
//      Host to Controller:  not allowd
//      Controller to Host:  allowed
// 11b
// A complete L2CAP PDU. Automatically flushable.
//
//
// Broadcast_Flag (BC Flag)
//
// in packet from Host to Controller:
// 00b No broadcast. Only point-to-point.
// 01b Active Slave Broadcast.
// 10b Parked Slave Broadcast.
// 11b Reserved for future use.
//
// in packet from Controller to Host:
// 00b Point-to-point
// 01b BR/EDR Packet received as a slave not in park state.
// 10b BR/EDR/Packet received as a slave in parks state.
//
//

enum PacketBoundaryFlag:UInt8 {
    case Unknown                              = 0x0f
    case FirstNonAutomaticallyFlushablePacket = 0x00
    case ContinuingFragment                   = 0x01
    case FirstAutomaticallyFlushablePacket    = 0x02
    case CompleteL2CAPPDU                     = 0x03
    
    func simpleDescription() -> String {
        switch self {
        case .Unknown:                              return "Unknown"
        case .FirstNonAutomaticallyFlushablePacket: return "FirstNonAutomaticallyFlushablePacket"
        case .ContinuingFragment:                   return "ContinuingFragment"
        case .FirstAutomaticallyFlushablePacket:    return "FirstAutomaticallyFlushablePacket"
        case .CompleteL2CAPPDU:                     return "CompleteL2CAPPDU"
        }
    }
}

class HCIACLDataPacket {
    var Handle:UInt16 = 0
    var Packet_Boundary_Flag:PacketBoundaryFlag = .Unknown
    var Broadcast_Flag:UInt8  = 0
    var DataTotalLength:UInt16 = 0
    var Data:[UInt8] = []

    var PDU:[UInt8] {
        get {
            var pdu = [UInt8](count:4, repeatedValue:0)
            pdu[0] = UInt8(Handle & 0x00ff)
            pdu[1] = (Broadcast_Flag << 6) | (Packet_Boundary_Flag.rawValue << 4) | UInt8(Handle >> 8)
            let length = UInt16(Data.count)
            pdu[2] = UInt8(length & 0x00ff)
            pdu[3] = UInt8(length >> 8)

            return pdu + Data
        }
    }
    
    init() {
    }
    
    init(packet:[UInt8]) {
        Handle               = UInt16(packet[0]) | UInt16(packet[1] & 0x0f) << 8
        Packet_Boundary_Flag = PacketBoundaryFlag(rawValue: (packet[1] & 0b00110000) >> 4 )!
        Broadcast_Flag       = (packet[1] & 0b11000000) >> 6
        DataTotalLength      = UInt16(packet[2]) | UInt16(packet[3]) << 8
        Data                 = [UInt8](packet[4..<packet.count])
    }
    
    init(Handle:UInt16, Packet_Boundary_Flag:PacketBoundaryFlag, Broadcast_Flag:UInt8, Data:[UInt8]) {
        self.Handle = Handle
        self.Packet_Boundary_Flag = Packet_Boundary_Flag
        self.Broadcast_Flag = Broadcast_Flag
        self.Data = Data
    }
    
    func arrayToString(packet:[UInt8]) -> String {
        var str = "["
        for val in packet {
            str += String(format:"0x%02x, ", val)
        }
        str += "]"
        
        return str
    }
    
    func simpleDescription() -> String {
        return String(format:"Handle:0x%04x", Handle)
            + " PB Flag:" + Packet_Boundary_Flag.simpleDescription()
            + String(format:" BC Flag:0x%02x", Broadcast_Flag)
            + " Data:" + self.arrayToString(Data)
    }
}
