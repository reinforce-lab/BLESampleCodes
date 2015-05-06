//
//  HCIEventParser.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/20.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

class HCIEventParser {
    
    // イベントパケットを解析します。
    class func parse(packet:[UInt8]) -> (HCIEvent) {
        let event      = HCIEventCode(rawValue: packet[0])
        let parameters = (packet.count >= 3) ? [UInt8](packet[2..<packet.count]) : [];
        
        if event == nil {
            return HCIEvent(eventCode:HCIEventCode.UnknownError, parameters:parameters)
        }
        
        switch event! {
        case .CommandCompleted:
            return HCIEventCommandComplete(packet:packet)
        case .CommandStatus:
            return HCIEventCommandStatus(packet:packet)
        case .NumberOfCompletedPackets:
            return HCIEventNumberOfCompletedPackets(packet: packet)
        case .EncryptionChange:
            return HCIEventEncryptionChange(packet: packet)
        case .EncryptionKeyRefreshComplete:
            return HCIEventEncryptionKeyRefreshComplete(packet: packet)
            
        case .LowEnergyEvent:
            switch parameters[0] {
            case 0x01:
                return HCIEventLEConnectionComplete(packet: packet)
            case 0x05:
                return HCIEventLELongTermKeyRequestEvent(packet: packet)
            default:
                return HCIEvent(eventCode:event!, parameters:parameters)
            }
        default:
            return HCIEvent(eventCode:event!, parameters:parameters)
        }
    }
}