//
//  SecurityManagerProtocol.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/05/06.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 633
// 3 SECURITY MANAGER PROTOCOL

enum SMPCommand:UInt8 {
    case Reserved        = 0x00
    case PairingRequest  = 0x01
    case PairingResponse = 0x02
    case PairingConfirm  = 0x03
    case PairingRandom   = 0x04
    case PairingFailed   = 0x05
    case EncryptionInformation = 0x06
    case MasterIdentification  = 0x07
    case IdentityInformation   = 0x08
    case IdentityAddressInformation = 0x09
    case SigningInformation = 0x0a
    case SecurityRequest    = 0x0b
    case PairingPublicKey   = 0x0c
    case PairingKeypressNotification = 0x0e
    
    func simpleDescription() -> String {
        switch self {
        case .Reserved:        return "Reserved"
        case .PairingRequest:  return "PairingRequest"
        case .PairingResponse: return "PairingResponse"
        case .PairingConfirm:  return "PairingConfirm"
        case .PairingRandom:   return "PairingRandom"
        case .PairingFailed:   return "PairingFailed"
        case .EncryptionInformation: return "EncryptionInformation"
        case .MasterIdentification:  return "MasterIdentification"
        case .IdentityInformation:   return "IdentityInformation"
        case .IdentityAddressInformation:   return "IdentityAddressInformation"
        case .SigningInformation: return "SigningInformation"
        case .SecurityRequest:    return "SecurityRequest"
        case .PairingPublicKey:   return "PairingPublicKey"
        case .PairingKeypressNotification: return "PairingKeypressNotification"
        }
    }
}

class SecurityManagerProtocolPDUFactory {
    class func parseSecurityManagerProtocolPDU(pdu:[UInt8]) -> SecurityManagerProtocolPDU {
        let code = SMPCommand(rawValue:pdu[0])!
        switch code {
        case .PairingRequest:  return PairingRequest(pdu: pdu)
//      case .PairingResponse: return PairingResponse(pdu:pdu)
        case .PairingConfirm:  return PairingConfirm(pdu:pdu)
        case .PairingRandom:   return PairingRandom(pdu:pdu)
        case .PairingFailed:   return PairingFailed(pdu:pdu)
        case .EncryptionInformation: return EncryptionInformation(pdu:pdu)
        case .MasterIdentification:  return MasterIdentification(pdu: pdu)
        case .IdentityInformation:   return IdentityInformation(pdu:pdu)
        case .IdentityAddressInformation:   return IdentityAddressInformation(pdu:pdu)
        case .SigningInformation:    return SigningInformation(pdu:pdu)
        case .SecurityRequest:    return SecurityRequest(pdu:pdu)
//      case .PairingPublicKey:
//      case .PairingKeypressNotification:
        default: return SecurityManagerProtocolPDU(pdu:pdu)
            
        }
    }
}

class SecurityManagerProtocolPDU {
    var Code:SMPCommand = .Reserved
    var Data:[UInt8] = []
    
    var PDU:[UInt8] {
        get {
            var pdu = [UInt8](count:1, repeatedValue:0)
            pdu[0] = Code.rawValue
            return pdu + Data
        }
    }
    
    init(code:SMPCommand) {
        self.Code = code
    }
    
    init(code:SMPCommand, data:[UInt8]) {
        self.Code = code
        self.Data = data
    }
    
    init(pdu:[UInt8]) {
        Code = SMPCommand(rawValue:pdu[0])!
        if pdu.count > 1 {
            Data = [UInt8](pdu[1..<pdu.count])
        }
    }
    
    func arrayToString(data:[UInt8]) -> String {
        var elements:[String] = []
        for val in data {
            elements += [String(format:"0x%02x", val)]
        }
        let joiner = " ,"
        
        return "[" + joiner.join(elements) + "]"
    }

    
    func boolToString(val:Bool) -> String {
        return val ? "true" : "false"
    }
    
    func simpleDescription() -> String {
        return "Code:" + Code.simpleDescription() + " Data:" + self.arrayToString(Data)
    }
}

enum IOCapabityType:UInt8 {
    case DisplayOnly  = 0x00
    case DisplayYesNo = 0x01
    case KeyboardOnly = 0x02
    case NoInputNoOutput = 0x03
    case KeyboardDisplay = 0x04
    
    func simpleDescription() -> String {
        switch self {
        case .DisplayOnly:     return "DisplayOnly"
        case .DisplayYesNo:    return "DisplayYesNo"
        case .KeyboardOnly:    return "KeyboardOnly"
        case .NoInputNoOutput: return "NoInputNoOutput"
        case .KeyboardDisplay: return "KeyboardDisplay"
        }
    }
}

enum OOBDataFlagType:UInt8 {
    case OOBAuthenticationDataNotPresent = 0x00
    case OOBAuthenticationDataFromRemoteDevicePresent = 0x01
    
    func simpleDescription() -> String {
        switch self {
        case .OOBAuthenticationDataNotPresent: return "OOBAuthenticationDataNotPresent"
        case .OOBAuthenticationDataFromRemoteDevicePresent: return "OOBAuthenticationDataFromRemoteDevicePresent"
        }
    }
}

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 637
//
// LSB
//     0 : 1           2       3        4        5 : 7
// +---------------+-------+-------+----------+----------+
// | Bonding_Flags | MITM  | SC    | Keypress | Reserved |
// | 2 bits        | 1 bit | 1 bit | 1 bit    | 3 bits   |
// +---------------+-------+-------+---------------------+
//
// Figure 3.3: Authentication Requirements Flags

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 647
//
// LSB
//     0       1       2       3        4 : 7
// +--------+-------+-------+--------+----------+
// | EncKey | IdKey | Sign  | LinKey | Reserved |
// | 1 bit  | 1 bit | 1 bit | 1 bit  | 4 bits   |
// +--------+-------+-------+--------+----------+
//
// Figure 3.11: LE Key Distribution Format
enum KeyDistributionFormat:UInt8 {
    case EncKey  = 0x01
    case IdKey   = 0x02
    case Sign    = 0x04
    case LinkKey = 0x08
    
    func simpleDescription() -> String {
        switch self {
        case .EncKey:  return "EncKey"
        case .IdKey:   return "IdKey"
        case .Sign:    return "Sign"
        case .LinkKey: return "LinkKey"
        }
    }
}

class PairingRequest: SecurityManagerProtocolPDU {
    var IOCapability:IOCapabityType    = .NoInputNoOutput
    var OOBDataFlag:OOBDataFlagType    = .OOBAuthenticationDataNotPresent
    var AuthReq:UInt8                  = 0
    var MaximumEncryptionKeySize:UInt8 = 0
    var InitiatorKeyDistribution:UInt8 = 0
    var ResponderKeyDistribution:UInt8 = 0
    
    // AuthReq
    var BondingFlags:Bool = false
    var MITM:Bool         = false
    var SC:Bool           = false
    var Keypress:Bool     = false
    
    override init(code:SMPCommand) {
        super.init(code:code)
    }
    
    override init(pdu:[UInt8]) {
        super.init(pdu:pdu)
        
        IOCapability = IOCapabityType(rawValue:  Data[0])!
        OOBDataFlag  = OOBDataFlagType(rawValue: Data[1])!
        AuthReq      = Data[2]
        MaximumEncryptionKeySize = Data[3]
        InitiatorKeyDistribution = Data[4]
        ResponderKeyDistribution = Data[5]
        
        // AuthReq
        BondingFlags  = ((0x03 & AuthReq) != 0)
        MITM          = ((0x04 & AuthReq) != 0)
        SC            = ((0x08 & AuthReq) != 0)
        Keypress      = ((0x10 & AuthReq) != 0)
    }
    
    func formatToString(format:UInt8) -> String {
        var desc = ""

        for flag:KeyDistributionFormat in [.EncKey, .IdKey, .Sign, .LinkKey] {
            if flag.rawValue & format != 0 {
                desc += flag.simpleDescription() + ","
            }
        }
        return desc
    }
        
    override func simpleDescription() -> String {
        var desc = super.simpleDescription()
            + "\n\t" + "IOCapability:" + IOCapability.simpleDescription()
            + "\n\t" + "OOBDataFlag:" + OOBDataFlag.simpleDescription()
        desc += "\n\tAuthReq:"
        desc += "\n\t\t Bonding_Flags:" + self.boolToString(BondingFlags)
        desc += "\n\t\t MITM:"          + self.boolToString(MITM)
        desc += "\n\t\t SC:"          + self.boolToString(SC)
        desc += "\n\t\t Keypress:"      + self.boolToString(Keypress)
        desc +=
              "\n\t" + String(format:"MaximumEncryptionKeySize:%d", MaximumEncryptionKeySize)
            + "\n\t" + String(format:"InitiatorKeyDistribution:0x%02x", InitiatorKeyDistribution)
            + "\n\t\t" + self.formatToString(InitiatorKeyDistribution)
            + "\n\t" + String(format:"ResponderKeyDistribution:0x%02x", ResponderKeyDistribution)
            + "\n\t\t" + self.formatToString(ResponderKeyDistribution)
        return desc
    }
}

class PairingResponse: PairingRequest {
    
    init(IOCapability:IOCapabityType, OOBDataFlag:OOBDataFlagType,
        // AuthReq
        BondingFlags:Bool, MITM:Bool, SC:Bool, Keypress:Bool,
        MaximumEncryptionKeySize:UInt8, InitiatorKeyDistribution:UInt8, ResponderKeyDistribution:UInt8) {
            super.init(code:.PairingResponse)
            
            self.BondingFlags = BondingFlags
            self.OOBDataFlag  = OOBDataFlag
            self.BondingFlags = BondingFlags
            
            self.MITM = MITM
            self.SC   = SC
            self.Keypress = Keypress
            
            self.MaximumEncryptionKeySize = MaximumEncryptionKeySize
            self.InitiatorKeyDistribution = InitiatorKeyDistribution
            self.ResponderKeyDistribution = ResponderKeyDistribution
            
            AuthReq = 0
            if BondingFlags {
                AuthReq |= 0x01
            }
            if MITM {
                AuthReq |= 0x04
            }
            if SC {
                AuthReq |= 0x08
            }
            if Keypress {
                AuthReq |= 0x10
            }
            
            Data = [UInt8](count:6, repeatedValue:6)
            Data[0] = IOCapability.rawValue
            Data[1] = OOBDataFlag.rawValue
            Data[2] = AuthReq
            Data[3] = MaximumEncryptionKeySize
            Data[4] = InitiatorKeyDistribution
            Data[5] = ResponderKeyDistribution
    }
}

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 639
// 3.5.3 Pairing Confirm
class PairingConfirm : SecurityManagerProtocolPDU {
    var ConfirmValue:[UInt8] = []
    
    override init(pdu:[UInt8]) {
        super.init(pdu: pdu)
        ConfirmValue = Data.reverse()
    }
    
    init(confirmValue:[UInt8]) {
        ConfirmValue = confirmValue
        
        super.init(code:.PairingConfirm, data:confirmValue.reverse())
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription() + "\n\tConfirmValue:" + self.arrayToString(ConfirmValue)
    }
}

class PairingRandom : SecurityManagerProtocolPDU {
    var RandomValue:[UInt8] = []
    
    override init(pdu:[UInt8]) {
        super.init(pdu: pdu)
        RandomValue = Data.reverse()
    }
    
    init(randomValue:[UInt8]) {
        RandomValue = randomValue
        
        super.init(code:.PairingRandom, data:randomValue.reverse())
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription() + "\n\tRandomValue:" + self.arrayToString(RandomValue)
    }
}

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 642
// Table 3.7: Pairing Failed Reason Codes
enum PairingFailedReasonCodeType:UInt8 {
    case Reserved           = 0x00
    case PasskeyEntryFailed = 0x01
    case OOBNotAvailable    = 0x02
    case AuthenticationRequirements = 0x03
    case ConfirmValueFailed  = 0x04
    case PairingNotSupported = 0x05
    case EncryptionKeySize   = 0x06
    case CommandNotSupported = 0x07
    case UnspecifiedReason = 0x08
    case RepeatedAttempts  = 0x09
    case InvalidParameters = 0x0A
    case DHKeyCheckFailed  = 0x0B
    case NumericComparisonFailed = 0x0c
    case BR_EDRParingInProgress  = 0x0d
    case CrossTransportKeyDevivationGenerationNotAllowed = 0x0e
    
    func simpleDescription() -> String {
        switch self {
        case .Reserved:           return "Reserved"
        case .PasskeyEntryFailed: return "PasskeyEntryFailed"
        case .OOBNotAvailable:    return "OOBNotAvailable"
        case .AuthenticationRequirements: return "AuthenticationRequirements"
        case .ConfirmValueFailed:  return "ConfirmValueFailed"
        case .PairingNotSupported: return "PairingNotSupported"
        case .EncryptionKeySize:   return "EncryptionKeySize"
        case .CommandNotSupported: return "CommandNotSupported"
        case .UnspecifiedReason:   return "UnspecifiedReason"
        case .RepeatedAttempts:    return "RepeatedAttempts"
        case .InvalidParameters:   return "InvalidParameters"
        case .DHKeyCheckFailed:    return "DHKeyCheckFailed"
        case .NumericComparisonFailed: return "NumericComparisonFailed"
        case .BR_EDRParingInProgress:  return "BR_EDRParingInProgress"
        case .CrossTransportKeyDevivationGenerationNotAllowed: return "CrossTransportKeyDevivationGenerationNotAllowed"
        }
    }
}

class PairingFailed : SecurityManagerProtocolPDU {
    var Reason:PairingFailedReasonCodeType = .Reserved
    
    override init(pdu:[UInt8]) {
        super.init(pdu: pdu)
        Reason = PairingFailedReasonCodeType(rawValue: Data[0])!
    }
    
    init(reason:PairingFailedReasonCodeType) {
        Reason = reason
        
        super.init(code:.PairingFailed, data:[reason.rawValue])
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription() + "\n\tReason:" + Reason.simpleDescription()
    }
}

// Pairing Public Key
// This message is used only in LE security connections.
// Pairing CHKey Check
// KeypressNotification
//

class EncryptionInformation : SecurityManagerProtocolPDU {
    var LongTermKey:[UInt8] = []
    
    override init(pdu:[UInt8]) {
        super.init(pdu: pdu)
        LongTermKey = [UInt8]((Data[0...15]).reverse())
    }
    
    init(longTermKey:[UInt8]) {
        LongTermKey = longTermKey
        
        super.init(code:.EncryptionInformation, data:LongTermKey.reverse())
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription() + "\n\tLongTermKey:" + self.arrayToString(LongTermKey)
    }
}

class MasterIdentification : SecurityManagerProtocolPDU {
    var EDIV:[UInt8] = []
    var Rand:[UInt8] = []
    
    override init(pdu:[UInt8]) {
        super.init(pdu: pdu)
        EDIV = [UInt8](Data[0...1].reverse())
        Rand = [UInt8](Data[2...9].reverse())
    }
    
    init(EDIV:[UInt8], rand:[UInt8]) {
        self.EDIV = EDIV
        self.Rand = rand

        super.init(code:.MasterIdentification, data: EDIV.reverse() + Rand.reverse())
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\tEDIV:" + self.arrayToString(EDIV)
            + "\n\tRand:" + self.arrayToString(Rand)
    }
}

class IdentityInformation: SecurityManagerProtocolPDU {
    var IdentityResolvingKey:[UInt8] = []

    override init(pdu:[UInt8]) {
        super.init(pdu: pdu)
        IdentityResolvingKey = [UInt8]((Data[0...15]).reverse())
    }
    
    init(identityResolvingKey:[UInt8]) {
        IdentityResolvingKey = identityResolvingKey
        
        super.init(code:.IdentityInformation)
        Data = identityResolvingKey.reverse()
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription() + "\n\tIdentityResolvingKey:" + self.arrayToString(IdentityResolvingKey)
    }
}

class IdentityAddressInformation: SecurityManagerProtocolPDU {
    var AddrType:UInt8  = 0x00
    var BD_ADDR:[UInt8] = []
    
    override init(pdu:[UInt8]) {
        super.init(pdu: pdu)
        
        AddrType = Data[0]
        BD_ADDR  = [UInt8](Data[1...6].reverse())
    }
    
    init(addrType:UInt8, BD_ADDR:[UInt8]) {
        self.AddrType = addrType
        self.BD_ADDR  = BD_ADDR
        
        super.init(code:.IdentityInformation)
        Data = [AddrType] + BD_ADDR.reverse()
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\tAddrType:" + (AddrType == 0x00 ? "Public addresss." : "Random address")
            + "\n\tBD_ADDR:" + self.arrayToString(BD_ADDR)
    }
}

class SigningInformation: SecurityManagerProtocolPDU {
    var SignatureKey:[UInt8] = []
    
    override init(pdu:[UInt8]) {
        super.init(pdu: pdu)
        SignatureKey = [UInt8]((Data[0...15]).reverse())
    }
    
    init(signatureKey:[UInt8]) {
        SignatureKey = signatureKey
        
        super.init(code:.SigningInformation)
        Data = SignatureKey.reverse()
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\tSignatureKey:" + self.arrayToString(SignatureKey)
    }
}

class SecurityRequest: SecurityManagerProtocolPDU {
    var AuthReq:UInt8 = 0
    // AuthReq
    var BondingFlags:Bool = false
    var MITM:Bool         = false
    var SC:Bool           = false
    var Keypress:Bool     = false
    
    override init(pdu:[UInt8]) {
        super.init(pdu:pdu)
        
        AuthReq = Data[0]
        // AuthReq
        BondingFlags  = ((0x03 & AuthReq) != 0)
        MITM          = ((0x04 & AuthReq) != 0)
        SC            = ((0x08 & AuthReq) != 0)
        Keypress      = ((0x10 & AuthReq) != 0)
    }
    
    override func simpleDescription() -> String {
        var desc = super.simpleDescription()
        desc += "\n\tAuthReq:"
            + "\n\t\t Bonding_Flags:" + self.boolToString(BondingFlags)
            + "\n\t\t MITM:" + self.boolToString(MITM)
            + "\n\t\t Keypress:" + self.boolToString(Keypress)
        return desc
    }

}

