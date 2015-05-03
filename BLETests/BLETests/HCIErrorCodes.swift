//
//  HCIErrorCodes.swift
//  testusb
//
//  Created by AkihiroUehara on 2015/04/06.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part D] page 371
enum HCIErrorCode:UInt8 {
    case Success                        = 0x00
    
    case UnknownHCICommand              = 0x01
    case UnkownConnectionIdentifier     = 0x02
    case HardwareFailure                = 0x03
    case PageTimeOut                    = 0x04
    case AuthenticationFailure          = 0x05
    case PINorKeyMissing                = 0x06
    case MemoryCapacityExceeded         = 0x07
    case ConnectionTimeout              = 0x08
    case ConnectionLimitExceeded        = 0x09
    case SynchronousConnectionLimitToDeviceExceeded         = 0x0a
    case ACLConnectionAlreadyExists     = 0x0b
    case CommandDisallowed              = 0x0c
    case ConnectionRejectedDueToSecurityReasons             = 0x0d
    case ConnectionRejectedDueToUnacceptableBD_ADDR         = 0x0f
    case ConnectionAcceptTimeoutExceeded                    = 0x10
    case UnsupportedFeatureOrParameterValue                 = 0x11
    case InvalidHCICommandParameters    = 0x012
    case RemoteUserTerminatedConnection = 0x13
    case RemoteDeviceTerminatedConnectionDueToLowResources  = 0x14
    case RemoteDeviceTerminatedConnectionDueToPowerOff      = 0x15
    case ConnectionTerminateByLocalHost = 0x16
    case RepeatedAttempts               = 0x17
    case ParingNotAllowed               = 0x18
    case UnknownLMPPDU                  = 0x19
    case UnsupportedRemoteFeature_UnsupportedLMPFeature     = 0x1a
    case SCOOffsetRejected              = 0x1b
    case SCOIntervalRejected            = 0x1c
    case SCOAirModeRejected             = 0x1d
    case InvalidLMVParameters_InvalidLLParameters           = 0x1e
    case UnspecifiedError               = 0x1f
    case UnspportedLMPParameterValue_UnsupportedLLParameterValue    = 0x20
    case RoleChangeNotAllowed           = 0x21
    case LMPResponseTimeout_LLResponseTimeout               = 0x22
    case LMPErrorTransactionCollision   = 0x23
    case LMPPDUNotAllowed               = 0x24
    case EncryptionModeNotAcceptable    = 0x25
    case LinkKeyCannotBeChanged         = 0x26
    case RequestedQoSNotSupported       = 0x27
    case InstantPassed                  = 0x28
    case ParingWithUnitKeyNotSupported  = 0x29
    case DifferentTransactionCollision  = 0x2a
    case QoSUnacceptableParameter       = 0x2c
    case QoSRejected                    = 0x2d
    case ChannelAssessmentNotSupported  = 0x2e
    case InsufficientSecurity           = 0x2f
    case ParameterOutOfMandatoryRange   = 0x30
    case RoleSwitchPending              = 0x32
    case ReservedSlotViolation          = 0x34
    case RoleSwitchFailed               = 0x35
    case ExtendedInquiryResponseTooLarge = 0x36
    case SimpleParingNotSupportedByHost = 0x37
    case HostBusy_Paring                = 0x38
    case ConnectionRejectedDueToNotSuitableChannelFound = 0x39
    case ControllerBusy                         = 0x3a
    case UnacceptableConnectionParameters       = 0x3b
    case DirectedAdvertisingTimeout             = 0x3c
    case ConnectionTerminatedDueToMICFailure    = 0x3d
    case ConnectionFailedToBeEstablished        = 0x3e
    case MACConnectionFailed            = 0x3f
    case CoarseClockAdjustmentRejectedButWillTryToAdjustUsingClockDragging = 0x40
    
    func simpleDescription() -> String {
        switch self {
        case Success: return "Success"
        case UnknownHCICommand:             return "UnknownHCICommand"
        case UnkownConnectionIdentifier:    return "UnkownConnectionIdentifier"
        case HardwareFailure:               return "HardwareFailure"
        case PageTimeOut:                   return "PageTimeOut"
        case AuthenticationFailure:         return "AuthenticationFailure"
        case PINorKeyMissing:               return "PINorKeyMissing"
        case MemoryCapacityExceeded:        return "MemoryCapacityExceeded"
        case ConnectionTimeout:             return "ConnectionTimeout"
        case ConnectionLimitExceeded:       return "ConnectionLimitExceeded"
        case SynchronousConnectionLimitToDeviceExceeded: return "SynchronousConnectionLimitToDeviceExceeded"
        case ACLConnectionAlreadyExists:    return "ACLConnectionAlreadyExists"
        case CommandDisallowed:             return "CommandDisallowed"
        case ConnectionRejectedDueToSecurityReasons:        return "ConnectionRejectedDueToSecurityReasons"
        case ConnectionRejectedDueToUnacceptableBD_ADDR:    return "ConnectionRejectedDueToUnacceptableBD_ADDR"
        case ConnectionAcceptTimeoutExceeded:               return "ConnectionAcceptTimeoutExceeded"
        case UnsupportedFeatureOrParameterValue:    return "UnsupportedFeatureOrParameterValue"
        case InvalidHCICommandParameters:           return "InvalidHCICommandParameters"
        case RemoteUserTerminatedConnection:        return "RemoteUserTerminatedConnection"
        case RemoteDeviceTerminatedConnectionDueToLowResources: return "RemoteDeviceTerminatedConnectionDueToLowResources"
        case RemoteDeviceTerminatedConnectionDueToPowerOff:     return "RemoteDeviceTerminatedConnectionDueToPowerOff"
        case ConnectionTerminateByLocalHost:        return "ConnectionTerminateByLocalHost"
        case RepeatedAttempts:                      return "RepeatedAttempts"
        case ParingNotAllowed:                      return "ParingNotAllowed"
        case UnknownLMPPDU:                         return "UnknownLMPPDU"
        case UnsupportedRemoteFeature_UnsupportedLMPFeature: return "UnsupportedRemoteFeature_UnsupportedLMPFeature"
        case SCOOffsetRejected:                     return "SCOOffsetRejected"
        case SCOIntervalRejected:                   return "SCOIntervalRejected"
        case SCOAirModeRejected:                    return "SCOAirModeRejected"
        case InvalidLMVParameters_InvalidLLParameters: return "InvalidLMVParameters_InvalidLLParameters"
        case UnspecifiedError:                      return "UnspecifiedError"
        case UnspportedLMPParameterValue_UnsupportedLLParameterValue: return "UnspportedLMPParameterValue_UnsupportedLLParameterValue"
        case RoleChangeNotAllowed:                  return "RoleChangeNotAllowed"
        case LMPResponseTimeout_LLResponseTimeout:  return "LMPResponseTimeout_LLResponseTimeout"
        case LMPErrorTransactionCollision:          return "LMPErrorTransactionCollision"
        case LMPPDUNotAllowed:                      return "LMPPDUNotAllowed"
        case EncryptionModeNotAcceptable:           return "EncryptionModeNotAcceptable"
        case LinkKeyCannotBeChanged:                return "LinkKeyCannotBeChanged"
        case RequestedQoSNotSupported:              return "RequestedQoSNotSupported"
        case InstantPassed:                         return "InstantPassed"
        case ParingWithUnitKeyNotSupported:         return "ParingWithUnitKeyNotSupported"
        case DifferentTransactionCollision:         return "DifferentTransactionCollision"
        case QoSUnacceptableParameter:              return "QoSUnacceptableParameter"
        case QoSRejected:                           return "QoSRejected"
        case ChannelAssessmentNotSupported:         return "ChannelAssessmentNotSupported"
        case InsufficientSecurity:                  return "InsufficientSecurity"
        case ParameterOutOfMandatoryRange:          return "ParameterOutOfMandatoryRange"
        case RoleSwitchPending:                     return "RoleSwitchPending"
        case ReservedSlotViolation:                 return "ReservedSlotViolation"
        case RoleSwitchFailed:                      return "RoleSwitchFailed"
        case ExtendedInquiryResponseTooLarge:       return "ExtendedInquiryResponseTooLarge"
        case SimpleParingNotSupportedByHost:        return "SimpleParingNotSupportedByHost"
        case HostBusy_Paring:                       return "HostBusy_Paring"
        case ConnectionRejectedDueToNotSuitableChannelFound: return "ConnectionRejectedDueToNotSuitableChannelFound"
        case ControllerBusy:                        return "ControllerBusy"
        case UnacceptableConnectionParameters:      return "UnacceptableConnectionParameters"
        case DirectedAdvertisingTimeout:            return "DirectedAdvertisingTimeout"
        case ConnectionTerminatedDueToMICFailure:   return "ConnectionTerminatedDueToMICFailure"
        case ConnectionFailedToBeEstablished:       return "ConnectionFailedToBeEstablished"
        case MACConnectionFailed:                   return "MACConnectionFailed"
        case CoarseClockAdjustmentRejectedButWillTryToAdjustUsingClockDragging: return "CoarseClockAdjustmentRejectedButWillTryToAdjustUsingClockDragging"
        }
    }
}