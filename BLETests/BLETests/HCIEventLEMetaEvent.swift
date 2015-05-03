//
//  HCIEventLEMetaEvent.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/23.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 929
// 7.7.65 LE Meta Event

class HCIEventLEConnectionComplete: HCIEvent {
    var Subevent_Code:UInt8 = 0
    var Status:HCIErrorCode = .Success
    var Connection_Handle:UInt16 = 0
    var Role:UInt8 = 0
    var Peer_Adddress_Type:UInt8 = 0
    var Peer_Address:[UInt8] = []
    var Conn_Interval:UInt16 = 0
    var Conn_Latency:UInt16  = 0
    var Supervision_Timeout:UInt16  = 0
    var Master_Clock_Accuracy:UInt8 = 0
    
    override init(packet: [UInt8]) {
        super.init(packet:packet)

        Subevent_Code         = self.parameters[0]
        Status                = HCIErrorCode(rawValue: self.parameters[1] )!
        Connection_Handle     = UInt16(self.parameters[2]) | UInt16(self.parameters[3]) << 8
        Role                  = self.parameters[4]
        Peer_Adddress_Type    = self.parameters[5]
        Peer_Address          = ([UInt8](self.parameters[6...11])).reverse()
        Conn_Interval         = UInt16(self.parameters[12]) | UInt16(self.parameters[13]) << 8
        Conn_Latency          = UInt16(self.parameters[14]) | UInt16(self.parameters[15]) << 8
        Supervision_Timeout   = UInt16(self.parameters[16]) | UInt16(self.parameters[17]) << 8
        Master_Clock_Accuracy = self.parameters[18]
    }
    
    override func simpleDescription() -> String {
        return self.eventCode.simpleDescription() + ":"
            + "\n\t" + "Subevent_Code:LEConnectionComplete"
            + "\n\t" + "Status:" + Status.simpleDescription() + " "
            + "\n\t" + String(format:"Connection_Handle:0x%04x ", Connection_Handle)
            + "\n\t" + "Role:" + (Role == 0 ? "master " : "slave ")
            + "\n\t" + "Peer_Address_Type:" + (Peer_Adddress_Type == 0 ? "Public Device Address " : "Random Device Address ")
            + "\n\t" + "Peer_Address:" + self.arrayToString(Peer_Address) + " "
            + "\n\t" + String(format:"Conn_Interval:%f msec ", Double(Conn_Interval) * 1.25)
            + "\n\t" + String(format:"Conn_Latency:%d ", Conn_Latency)
            + "\n\t" + String(format:"Supervision_Timeout:%d msec ", Supervision_Timeout * 10)
            + "\n\t" + String(format:"Master_Clock_Accuracy:0x%02x", Master_Clock_Accuracy)
    }
}