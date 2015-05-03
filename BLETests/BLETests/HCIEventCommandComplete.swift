//
//  HCIEventCommandComplete.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/19.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 861
// 7.7.14 Command Complete Event

class HCIEventCommandComplete: HCIEvent {
    var Num_HCI_Command_Packets:UInt8 = 0
    var Command_Opcode:UInt16         = 0
    var Return_Parameters:[UInt8]     = []
    
    override init(packet: [UInt8]) {
        super.init(packet:packet)
        
        Num_HCI_Command_Packets = self.parameters[0]
        Command_Opcode          = UInt16(self.parameters[1]) | UInt16(self.parameters[2]) << 8
        Return_Parameters       = [UInt8](self.parameters[3..<self.parameters.count])
    }
    
    override func simpleDescription() -> String {
/*super.simpleDescription()*/
        return self.eventCode.simpleDescription() + ":"
            + String(format:" Num_HCI_Command_Packets:%d", Num_HCI_Command_Packets)
            + String(format:" Command_Opcode:0x%04x", Command_Opcode)
            + " Return_Parameters:" + self.arrayToString(Return_Parameters)
    }
}