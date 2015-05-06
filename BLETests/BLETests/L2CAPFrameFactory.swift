//
//  L2CAPDataPacket.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/23.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// ファクトリクラス
class L2CAPFrameFactory {
    var length:UInt16  = 0
    var packet:[UInt8] = []
    
    func parse(data:[UInt8]) -> L2CAPBasicFrame? {
        packet += data
        if length == 0 {
            length = UInt16(packet[0]) | (UInt16(packet[1]) << 8)
        }
        
        // 1つのフレームのデータが揃っていないので、nilを返します。
        if UInt16(packet.count) < (length + 4) {
            return nil
        }
    
        // パケットを切り出します
        let pdu = [UInt8](packet[0..<Int(length + 4)])
        if UInt16(packet.count) == (length + 4) {
            packet = []
        } else {
            packet = [UInt8](packet[Int(length + 4)..<packet.count])
        }
        length = 0
        
        let cid:UInt16 = UInt16(pdu[2]) | (UInt16(pdu[3]) << 8)
        if(cid == 0x0005) {
            return L2CAPControlFrame(data: pdu)
        } else {
            return L2CAPBasicFrame(data: pdu)
        }
    }
    
    func build(channelID:L2CAPChannelID, payload:[UInt8]) -> ([UInt8]) {
        var pdu    = [UInt8](count:4, repeatedValue:0)
        let length = UInt16(payload.count)
        pdu[0]  = UInt8(length & 0x00ff)
        pdu[1]  = UInt8(length >> 8)
        let cid = channelID.rawValue
        pdu[2] = UInt8(cid & 0x00ff)
        pdu[3] = UInt8(cid >> 8)

        return pdu + payload
    }
}

enum L2CAPFrameType:String {
    case BasicFrame   = "BasicFrame"
    case ControlFrame = "ControlFrame"
}

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part A] page 38
// 2.1 CHANNEL IDENTIFIERS
enum L2CAPChannelID:UInt16 {
    // CID name space for the ACCL-U and AMP-U logical links:
    /*
    case NullIdentifier        = 0x0000
    case L2CAPSignalingChannel = 0x0001
    case ConectionlessChannel  = 0x0002
    case AMPManagerProtocol = 0x0003
    case BREDRSecurityManager = 0x0007
    case AMPTestManager = 0x003F
*/

    // The CID name space fot the LE-U logical link:
    case NullIdentifier                 = 0x0000
    case AttributeProtocol              = 0x0004
    case LowEnergyL2CAPSignalingChannel = 0x0005
    case SecurityManagerProtocol        = 0x0006

    case UnknownChannelID = 0xffff
    
    // 0x0040-0x007F Dynamically allocated
    // Communicated using the L2CAP LE credit based create connection mechanism
    
    func simpleDescription() ->String{
        switch self{
        case .NullIdentifier:                 return "NullIdentifier"
        case .AttributeProtocol:              return "AttributeProtocol"
        case .LowEnergyL2CAPSignalingChannel: return "LowEnergyL2CAPSignalingChannel"
        case .SecurityManagerProtocol:        return "SecurityManagerProtocol"
        case .UnknownChannelID:               return "UnknownChannelID"
        }
    }
}

//
// BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part A] page 45
// 3 DATA PACKET FORMAT
//
// 0        16        32
// +--------+---------+----------------------+
// | Length | Channel | Information payload  |
// |        | ID      |                      |
// +--------+---------+----------------------+ MSB
// Basic information frame (B-frame)
//
//
// L2CAP PDU type with protocol elements in addition to the Basic L2CAP header to support LE Credit Based Flow Control Mode.
// 0        16        32                 48
// +--------+---------+------------------+---------------------+
// | Length | Channel | L2CAP SDU Length |Information payload  |
// |        | ID      |                  |                     |
// +--------+---------+------------------+---------------------+ MSB
// LE information frame (LE-frame)
//
// BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part A] page 57
// Signaling packet format
// 0        16        32                 48
// +--------+---------+------------------+---------------------+
// | Length | Channel | L2CAP SDU Length |Information payload  |
// |        | ID(0x05)|                  |                     |
// +--------+---------+------------------+---------------------+ MSB
// L2CAP PDU format on a signaling channel(C-frame)
//
// Command format which contained in Information payload
//      0        1          2  3             (octet)
// +--------+------------+--------+-------+
// | Code   | Identifier | Length | data  |
// +--------+------------+--------+-------+


class L2CAPBasicFrame {
    var Length:UInt16 = 0
    var ChannelID:L2CAPChannelID = .NullIdentifier
    var InformationPayload:[UInt8] = []

    var FrameType:L2CAPFrameType = L2CAPFrameType.BasicFrame
    var RawChannelID:UInt16 = 0
    
/*
    var PDU:[UInt8] {
        get {
            var pdu = [UInt8](count:4, repeatedValue:0)
            pdu[0]  = UInt8(self.Length & 0x00ff)
            pdu[1]  = UInt8(self.Length >> 8)
            let cid = self.ChannelID.rawValue
            pdu[2]  = UInt8(cid & 0x00ff)
            pdu[3]  = UInt8(cid >> 8)

            return pdu + InformationPayload
        }
    }
*/    
    init(data:[UInt8]) {
        Length    = UInt16(data[0]) | UInt16(data[1]) << 8
        RawChannelID = UInt16(data[2]) | (UInt16(data[3]) << 8)
        ChannelID = L2CAPChannelID(rawValue:RawChannelID) ?? .UnknownChannelID
        InformationPayload = [UInt8](data[4..<data.count])
    }
    
    init(ChannelID:L2CAPChannelID, InformationPayload:[UInt8]) {
        self.Length    = UInt16(InformationPayload.count)
        self.ChannelID = ChannelID
        self.InformationPayload = InformationPayload
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
        var desc = ""
        desc += "ChannelID:" + ChannelID.simpleDescription()
        if(ChannelID == .UnknownChannelID) {
            desc += String(format:"(raw value:0x%04x)", RawChannelID)
        }
        desc += " InformationPayload:" + self.arrayToString(InformationPayload)
        return desc
    }
}

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part A] page 58
enum L2CAPCommandCode:UInt8 {
    case Reserved      = 0x00
    case CommandReject = 0x01
    case DisconnectionRequest  = 0x06
    case DisconnectionResponse = 0x07
    case ConnectionParameterUpdateRequest  = 0x12
    case ConnectionParameterUpdateResponse = 0x13
    case LECreditBasedConnectionRequest  = 0x14
    case LECreditBasedConnectionResponse = 0x15
    case LEFlowControlCredit = 0x16
    
    func simpleDescription() -> String {
        switch self{
            case .Reserved:                          return "Reserved"
            case .CommandReject:                     return "CommandReject"
            case .DisconnectionRequest:              return "DisconnectionRequest"
            case .DisconnectionResponse:             return "DisconnectionResponse"
            case .ConnectionParameterUpdateRequest:  return "ConnectionParameterUpdateRequest"
            case .ConnectionParameterUpdateResponse: return "ConnectionParameterUpdateResponse"
            case .LECreditBasedConnectionRequest:    return "LECreditBasedConnectionRequest"
            case .LECreditBasedConnectionResponse:   return "LECreditBasedConnectionResponse"
            case .LEFlowControlCredit:               return "LEFlowControlCredit"
        }
    }
}

class L2CAPControlFrame:L2CAPBasicFrame {
    var CommandCode:L2CAPCommandCode = .Reserved
    var Identifier:UInt8 = 0
    var Parameters:[UInt8] = []
    
    override init(data:[UInt8]) {
        super.init(data:data)
        self.FrameType   = .ControlFrame
        self.CommandCode = L2CAPCommandCode(rawValue: self.InformationPayload[0])!
        self.Identifier  = self.InformationPayload[1]
        self.Parameters  = [UInt8](self.InformationPayload[4..<self.InformationPayload.count])
    }
    
    override func simpleDescription() -> String {
        // パラメータの詳細説明
        var parameterDesc = ""
        switch CommandCode {
        case .CommandReject:
            let reasonValue = UInt16(Parameters[0]) | (UInt16(Parameters[1]) << 8)
            var reason = ""
            switch reasonValue {
            case 0x0000: reason = "Command not understood"
            case 0x0001: reason = "Signaling MTU exceeded"
            case 0x0002: reason = "Invalid CID in request"
            default: reason = "Reserved"
            }
            var datadesc = ""
            switch reasonValue {
            case 0x0001:
                datadesc = String(format:" Actual MTUsig is %d", (UInt16(Parameters[2]) | UInt16(Parameters[3]) << 8))
            case 0x0002:
                datadesc = String(format:" Requested CID is 0x%04x",
                    UInt32(Parameters[2]) | UInt32(Parameters[3]) << 8 | UInt32(Parameters[4]) << 16 | UInt32(Parameters[5]) << 24
                )
            default:
                datadesc = ""
            }
            parameterDesc = "reason:" + reason + datadesc
        case .DisconnectionRequest:
            parameterDesc = String(format:" Destination CID:0x%04x SourceID:%04x",
                ((UInt16(Parameters[0]) | UInt16(Parameters[1]) << 8)),
                ((UInt16(Parameters[2]) | UInt16(Parameters[3]) << 8))
            )
        case .ConnectionParameterUpdateResponse:
            parameterDesc = String(format:" Interval Min:%f msec Interval Max:%f msec Slave Latency:%d Timeout Mutiplier:%f msec",
                1.25 * Double((UInt16(Parameters[0]) | UInt16(Parameters[1]) << 8)),
                1.25 * Double((UInt16(Parameters[2]) | UInt16(Parameters[3]) << 8)),
                ((UInt16(Parameters[4]) | UInt16(Parameters[5]) << 8)),
                ((UInt16(Parameters[6]) | UInt16(Parameters[7]) << 8)))
        case .ConnectionParameterUpdateResponse:
            switch ((UInt16(Parameters[0]) | UInt16(Parameters[1]) << 8)) {
            case 0x0000: parameterDesc = "Connection Parameters accepted"
            case 0x0001: parameterDesc = "Connection Parameters rejected"
            default:  parameterDesc = "Reserved"
            }
        case .LECreditBasedConnectionRequest:
            parameterDesc = String(format:" LE_PSM:0x%04x Source CID:0x%04x MTU:0x%04x MPS:0x%04x Initial Credits:0x%04x",
                ((UInt16(Parameters[0]) | UInt16(Parameters[1]) << 8)),
                ((UInt16(Parameters[2]) | UInt16(Parameters[3]) << 8)),
                ((UInt16(Parameters[4]) | UInt16(Parameters[5]) << 8)),
                ((UInt16(Parameters[6]) | UInt16(Parameters[7]) << 8)),
                ((UInt16(Parameters[8]) | UInt16(Parameters[9]) << 8))
            )
        case .LECreditBasedConnectionResponse:
            parameterDesc = String(format:" Destination CID:0x%04x MTU:0x%04x MPS:0x%04x Initial Credits:0x%04x Results:0x%04x",
                ((UInt16(Parameters[0]) | UInt16(Parameters[1]) << 8)),
                ((UInt16(Parameters[2]) | UInt16(Parameters[3]) << 8)),
                ((UInt16(Parameters[4]) | UInt16(Parameters[5]) << 8)),
                ((UInt16(Parameters[6]) | UInt16(Parameters[7]) << 8)),
                ((UInt16(Parameters[8]) | UInt16(Parameters[9]) << 8))
            )
        case .LEFlowControlCredit:
            parameterDesc = String(format:" CID:0x%04x Credits:0x%04x",
                ((UInt16(Parameters[0]) | UInt16(Parameters[1]) << 8)),
                ((UInt16(Parameters[2]) | UInt16(Parameters[3]) << 8))
            )
        default:
            parameterDesc = ""
        }
    
        return "ChannelID:" + ChannelID.simpleDescription() + " InformationPayload:" + self.arrayToString(InformationPayload) + "\n\tParameters:: " + parameterDesc
    }
}

