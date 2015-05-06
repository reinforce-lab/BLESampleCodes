//
//  HCIEventPacket.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/19.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

//
// BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 477
// HCIイベントパケットは、先頭1オクテットのイベントコード、それにパラメータのオクテット数を表す1オクテットの値、パラメータが続きます。
//
// 0                 8              16          24          32
// +-----------------+--------------+-----------+-----------+--
// | Event Code      | Parameter    |Parameter0 |Parameter1 | ...
// |                 | Total Length |           |           |
// +--------+--------+--------------+-----------+-----------+---
//

class HCIEvent {
    let eventCode:HCIEventCode
    let parameters:[UInt8]
    
    init(packet:[UInt8]) {
        self.eventCode  = HCIEventCode(rawValue: packet[0])!
        self.parameters = [UInt8](packet[2..<packet.count])
    }
    
    init(eventCode:HCIEventCode, parameters:[UInt8]) {
        self.eventCode  = eventCode
        self.parameters = parameters
    }
    
    func arrayToString(data:[UInt8]) -> String {
        var elements:[String] = []
        for val in data {
            elements += [String(format:"0x%02x", val)]
        }
        let joiner = " ,"
        
        return "[" + joiner.join(elements) + "]"
    }
    
    func simpleDescription() -> String {
        return "event:\(eventCode.simpleDescription()) parameters:" + self.arrayToString(parameters) + "."
    }
}
