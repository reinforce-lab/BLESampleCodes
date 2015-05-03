//
//  HCIEventCommandStatus.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/20.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 862
// 7.7.15 Command Status Event

class HCIEventCommandStatus: HCIEvent {
    var Status:UInt8 = 0
    var Num_HCI_Command_Packets:UInt8 = 0
    var Command_Opcode:UInt16         = 0
    
    override init(packet: [UInt8]) {
        super.init(packet:packet)

        Status = self.parameters[0]
        Num_HCI_Command_Packets = self.parameters[1]
        Command_Opcode          = UInt16(self.parameters[2]) | UInt16(self.parameters[3]) << 8
    }
    
    override func simpleDescription() -> String {
        /*super.simpleDescription()*/
        return self.eventCode.simpleDescription() + ":"
            + String(format:" Status:0x%02x", Status)
            + String(format:" Num_HCI_Command_Packets:%d", Num_HCI_Command_Packets)
            + String(format:" Command_Opcode:0x%04x", Command_Opcode)
    }
}