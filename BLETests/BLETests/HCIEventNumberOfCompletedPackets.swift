//
//  HCIEventNumberOfCompletedPackets.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/05/04.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 867
// 7.7.19 Number Of Completed Packets Event

class HCIEventNumberOfCompletedPackets: HCIEvent {
    var Number_of_Handles:UInt8 = 0
    var Connection_Handle:[UInt16] = []
    var HC_Num_Of_Completed_Packets:[UInt16] = []
    
    override init(packet: [UInt8]) {
        super.init(packet:packet)

        Number_of_Handles = self.parameters[0]
        
        // バイト配列を読み取っていく
        Connection_Handle = [UInt16](count:Int(Number_of_Handles), repeatedValue:0)
        var index = 1
        for i in 0..<Int(Number_of_Handles) {
            Connection_Handle[i] = UInt16(parameters[index]) | UInt16(parameters[index + 1]) << 8
            index += 2
        }
        
        HC_Num_Of_Completed_Packets = [UInt16](count:Int(Number_of_Handles), repeatedValue:0)
        for i in 0..<Int(Number_of_Handles) {
            HC_Num_Of_Completed_Packets[i] = UInt16(parameters[index]) | UInt16(parameters[index + 1]) << 8
            index += 2
        }
    }
    
    override func simpleDescription() -> String {
        var desc = self.eventCode.simpleDescription() + ":"
        desc += String(format:"\n\t Number_of_Handles:%d", Number_of_Handles)
        for i in 0..<Int(Number_of_Handles) {
            desc += String(format:"\n\t Connection_Handle[%d]:0x%04x", i, Connection_Handle[i])
            desc += String(format:"\n\t HC_Num_Of_Completed_Packets[%d]:%d", i, HC_Num_Of_Completed_Packets[i])
        }
        return desc
    }
}