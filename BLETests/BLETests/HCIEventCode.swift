//
//  HCIEvent.swift
//  testusb
//
//  Created by AkihiroUehara on 2015/04/06.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// 参照
// BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 843
// 7.7 Events

//HCIのエラーコードの列挙型
//LE関連のイベントは、0x3eの同じ値が割り当てられているので、LowEnergyEventに定義をまとめている。
enum HCIEventCode:UInt8 {
    case UnknownError = 0x00
    
    // Generic Events
    case CommandCompleted   = 0x0e
    case CommandStatus      = 0x0f
    case HardwareError      = 0x10

    // Controller Flow Control
    case NumberOfCompletedPackets   = 0x13

    // Device Discovery
    case DisconnectionComplete = 0x05
    
    // Remote Information
    case ReadRemoteVersionInformationComplete = 0x0c

    // Host Flow Control
    case DataBufferOverflow = 0x1a

    // Authentication and Encryption
    case EncryptionChange = 0x08
    case EncryptionKeyRefreshComplete = 0x30
    case AuthenticatedPayloadTimeoutExpired = 0x57

    // LE events
    case LowEnergyEvent = 0x3e
    
    func simpleDescription() -> String {
        switch self {
        case UnknownError:                          return "UnknownError"
        case CommandCompleted:                      return "CommandCompleted"
        case CommandStatus:                         return "CommandStatus"
        case HardwareError:                         return "HardwareError"
        case NumberOfCompletedPackets:              return "NumberOfCompletedPackets"
        case DisconnectionComplete:                 return "DisconnectionComplete"
        case ReadRemoteVersionInformationComplete:  return "ReadRemoteVersionInformationComplete"
        case DataBufferOverflow:                    return "DataBufferOverflow"
        case EncryptionChange:                      return "EncryptionChange"
        case EncryptionKeyRefreshComplete:          return "EncryptionKeyRefreshComplete"
        case AuthenticatedPayloadTimeoutExpired:    return "AuthenticatedPayloadTimeoutExpired"
        case LowEnergyEvent:                        return "LowEnergyEvent"
        }
    }
}