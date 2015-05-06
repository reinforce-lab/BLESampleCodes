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
    var Peer_Address_Type:UInt8 = 0
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
        Peer_Address_Type     = self.parameters[5]
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
            + "\n\t" + "Peer_Address_Type:" + (Peer_Address_Type == 0 ? "Public Device Address " : "Random Device Address ")
            + "\n\t" + "Peer_Address:" + self.arrayToString(Peer_Address) + " "
            + "\n\t" + String(format:"Conn_Interval:%f msec ", Double(Conn_Interval) * 1.25)
            + "\n\t" + String(format:"Conn_Latency:%d ", Conn_Latency)
            + "\n\t" + String(format:"Supervision_Timeout:%d msec ", Supervision_Timeout * 10)
            + "\n\t" + String(format:"Master_Clock_Accuracy:0x%02x", Master_Clock_Accuracy)
    }
}

class HCIEventLELongTermKeyRequestEvent: HCIEvent {
    var Subevent_Code:UInt8      = 0
    var Connection_Handle:UInt16 = 0
    var Random_Number:[UInt8]    = []
    var Encrypted_Diversifier:UInt16 = 0
    
    override init(packet: [UInt8]) {
        super.init(packet:packet)
        
        Subevent_Code         = self.parameters[0]
        Connection_Handle     = UInt16(self.parameters[1]) | UInt16(self.parameters[2]) << 8
        Random_Number         = [UInt8](self.parameters[3...10].reverse())
        Encrypted_Diversifier = UInt16(self.parameters[11]) | UInt16(self.parameters[12]) << 8
    }
    
    override func simpleDescription() -> String {
        return self.eventCode.simpleDescription() + ":"
            + "\n\t" + "Subevent_Code:LELongTermKeyRequest"
            + "\n\t" + String(format:"Connection_Handle:0x%04x ", Connection_Handle)
            + "\n\t" + "Random_Number:" + self.arrayToString(Random_Number)
            + "\n\t" + String(format:"Encrypted_Diversifier:0x%04x ", Encrypted_Diversifier)
    }
}

//BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 852
//7.7.8 Encryption Change Event
class HCIEventEncryptionChange: HCIEvent {
    var Status:UInt8 = 0
    var Connection_Handle:UInt16 = 0
    var Encryption_Enabled:UInt8 = 0
    
    
    override init(packet: [UInt8]) {
        super.init(packet:packet)
        
        Status             = self.parameters[0]
        Connection_Handle  = UInt16(self.parameters[1]) | UInt16(self.parameters[2]) << 8
        Encryption_Enabled = self.parameters[3]
    }
    
    override func simpleDescription() -> String {
        var status_msg = (Status == 0x00) ? "Encryption change has occurred." : String(format:"Encryption change failed, 0x%02x.", Status)
        
        var msg = ""
        switch Encryption_Enabled {
        case 0x00: msg = "Link level encryption is off."
        case 0x01: msg = "link level encryption is on with AES-CCM for LE."
        case 0x02: msg = "link level encryption is on with AES-CCM for BD/EDR."
        default:   msg = "reserved."
        }
        
        return self.eventCode.simpleDescription() + ":"
            + "\n\t" + "Status:" + status_msg
            + "\n\t" + String(format:"Connection_Handle:0x%04x ", Connection_Handle)
            + "\n\t" + "Encryption_Enabled:" + msg
    }
}

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 899
// 7.7.39 Encryption Key Refresh Complete Event
class HCIEventEncryptionKeyRefreshComplete: HCIEvent {
    var Status:UInt8 = 0
    var Connection_Handle:UInt16 = 0
    
    override init(packet: [UInt8]) {
        super.init(packet:packet)
        
        Status             = self.parameters[0]
        Connection_Handle  = UInt16(self.parameters[1]) | UInt16(self.parameters[2]) << 8
    }
    
    override func simpleDescription() -> String {
        return self.eventCode.simpleDescription() + ":"
            + "\n\t" + String(format:"Status: %d", self.Status)
            + "\n\t" + String(format:"Connection_Handle:0x%04x ", Connection_Handle)
    }
}
