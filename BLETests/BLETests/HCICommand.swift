//
//  HCICommand.swift
//  testusb
//
//  Created by AkihiroUehara on 2015/04/06.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// コマンドの値を、OpCodeGroupuField と OpCodeCommmand Field の値を、上位と下位にした値で定義します。
enum HCIOpcodeCommand : UInt32 {
    // Link control commands OGF=0x01
    case Disconnect                     = 0x00010006
    case ReadRemoteVersionInformation   = 0x0001001d
    
    // Device Setup OGF = 0x03
    case SetEventMask                   = 0x00030001
    case Reset                          = 0x00030003
    case ReadTransmitPowerLevel         = 0x0003002d
    case SetControllerToHostFlowControl = 0x00030031
    case HostBufferSize                 = 0x00030033
    case HostNumberOfCompletedPackets   = 0x00030035
    
    // INFORMATIONAL PARAMETERS OGF = 0x04
    case ReadLocalVersionInformation    = 0x00040001
    case ReadLocalSupportedCommands     = 0x00040002
    case ReadLocalSupportedFeatuers     = 0x00040003
    case ReadBufferSize                 = 0x00040005
    case ReadBD_ADDR                    = 0x00040009
    
    // Status Parameters OGF = 0x05
    case ReadRSSI                       = 0x00050005
    
    // LE Controller Commands OGF = 0x08
    case LESetEventMask                 = 0x00080001
    case LEReadBufferSize               = 0x00080002
    case LEReadLocalSupportedFeatures   = 0x00080003
    case LESetRandomAddress             = 0x00080005
    case LESetAdvertisingParameters     = 0x00080006
    case LEReadAdvertisingChannelTxPower = 0x00080007
    case LESetAdvertisingData           = 0x00080008
    case LESetScanResponseData          = 0x00080009
    case LESetAdvertiseEnable           = 0x0008000a
    case LESetScanParameters            = 0x0008000b
    case LESetScanEnable                = 0x0008000c
    case LECreateConnection             = 0x0008000d
    case LECreateConnectionCancel       = 0x0008000e
    case LEReadWhiteListSize            = 0x0008000f
    case LEClearWhiteList               = 0x00080010
    case LEAddDeviceToWhiteList         = 0x00080011
    case LERemoveDeviceFromWhiteList    = 0x00080012
    case LEConnectionUpdate             = 0x00080013
    case LESetHostChannelClassification = 0x00080014
    case LEReadChannelMap               = 0x00080015
    case LEReadRemoteUsedFeatures       = 0x00080016
    case LEEncrypt                      = 0x00080017
    case LERand                         = 0x00080018
    case LEStartEncryption              = 0x00080019
    case LELongTermKeyRequestReply      = 0x0008001A
    case LELongTermKeyRequestNegativeReply  = 0x0008001B
    case LEReadSupportedStatus              = 0x0008001C
    
    // 今回使わなコマンドは、定義しません。
    //  Set MWS Channel Parameters Command          CSA3
    //  Set External Frame Confugration Command     CSA3
    //  Set MWS Signalighg Command                  CSA3
    //  Set MWS Transport Layer Command             CSA3
    //  Set MWS Transport Layer Configuration Command   CSA3
    //  Set MWS Scan Frequency Table Command            CSA3
    //  SET MWS_PATTERN Configuration Command           CSA3
    //  LE Read Maximum Data Length Command         4.2
    //  LE Set Resolvable Private Address Timeout Command   4.2
    //  LE Remote Connection Parameter Request Reply Command    4.1
    //  LE Remote Connection Parameter Request Negative Replya Command  4.1
    //  LE Set Data Length Command   4.2
    //  LE Read Suggested Default Data Length Command   4.2
    //  LE Write Suggested Default Data Length Command  4.2
    //  LE Add Device to Resolving List Command         4.2
    //  LE Remove Device From Resolving List Command    4.2
    // LE Clear Resolving List Command                  4.2
    // LE Read Resolving List Size Command              4.2
    // LE Read Peer Resolvable Address Command          4.2
    // LE Read Local Resolvable Address Command         4.2
    // LE Set Address Resolution Enable Command         4.2
    //  LE Read Local P-256 Public Key Command      4.2
    //  LE Generate DHKey Command    4.2
    
    //  Write Authenticated Payload Timeout Commmand 4.1
    //  Read Authenticated Payload Timeout Command   4.1
    
    // Testing
    //  LE Receiver Test Command
    //  LE Transmitter Test Command
    //  LE Test End Command
    
    func simpleDescription() ->String{
        switch self{
        case .Disconnect:                        return "Disconnect"
        case .ReadRemoteVersionInformation:      return "ReadRemoteVersionInformation"
            
        case .SetEventMask:                      return "SetEventMask"
        case .Reset:                             return "Reset"
        case .ReadTransmitPowerLevel:            return "ReadTransmitPowerLevel"
        case .SetControllerToHostFlowControl:    return "SetControllerToHostFlowControl:"
        case .HostBufferSize:                    return "HostBufferSize"
        case .HostNumberOfCompletedPackets:      return "HostNumberOfCompletedPackets"
            
        case .ReadLocalVersionInformation:       return "ReadLocalVersionInformation"
        case .ReadLocalSupportedCommands:        return "ReadLocalSupportedCommands"
        case .ReadLocalSupportedFeatuers:        return "ReadLocalSupportedFeatuers"
        case .ReadBufferSize:                    return "ReadBufferSize"
        case .ReadBD_ADDR:                       return "ReadBD_ADDR"
            
        case .ReadRSSI:                          return "ReadRSSI"
            
        case .LESetEventMask:                    return "LESetEventMask"
        case .LEReadBufferSize:                  return "LEReadBufferSize"
        case .LEReadLocalSupportedFeatures:      return "LEReadLocalSupportedFeatures"
        case .LESetRandomAddress:                return "LESetRandomAddress"
        case .LESetAdvertisingParameters:        return "LESetAdvertisingParameters"
        case .LEReadAdvertisingChannelTxPower:   return "LEReadAdvertisingChannelTxPower"
        case .LESetAdvertisingData:              return "LESetAdvertisingData"
        case .LESetAdvertiseEnable:              return "LESetAdvertiseEnable"
        case .LESetScanResponseData:             return "LESetScanResponseData"
        case .LESetScanParameters:               return "LESetScanParameters"
        case .LESetScanEnable:                   return "LESetScanEnable"
        case .LECreateConnection:                return "LECreateConnection"
        case .LECreateConnectionCancel:          return "LECreateConnectionCancel"
        case .LEReadWhiteListSize:               return "LEReadWhiteListSize"
        case .LEClearWhiteList:                  return "LEReadWhiteListSize"
        case .LEAddDeviceToWhiteList:            return "LEAddDeviceToWhiteList"
        case .LERemoveDeviceFromWhiteList:       return "LERemoveDeviceFromWhiteList"
        case .LEConnectionUpdate:                return "LEConnectionUpdate"
        case .LESetHostChannelClassification:    return "LESetHostChannelClassification"
        case .LEReadChannelMap:                  return "LEReadChannelMap"
        case .LEReadRemoteUsedFeatures:          return "LEReadRemoteUsedFeatures"
        case .LEEncrypt:                         return "LEEncrypt"
        case .LERand:                            return "LERand"
        case .LEStartEncryption:                 return "LEStartEncryption"
        case .LELongTermKeyRequestReply:         return "LELongTermKeyRequestReply"
        case .LELongTermKeyRequestNegativeReply: return "LELongTermKeyRequestNegativeReply"
        case .LEReadSupportedStatus:             return "LEReadSupportedStatus"
            
        default: return "Unknown"
        }
    }
}
