//
//  AttributeProtocolPDU.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/26.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

//
// BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part F] page 477
// 3.3 ATTRIBUTE PDU
//
//      1        0 to (ATT_MUX - X)    0 or 12    octs.
// +-----------+----------------------+----------------+
// | Attribute | Attribute            | Authentication |
// | Opcode    | Parameters           | Signature      |
// +-----------+----------------------+----------------+
//
// Attribute Opcode
//  bit7: Authentication Signature Flag
//  bit6: Command Flag
//  bit5-0: Method
//
// Attribute Parameters
//  X = 1  if authenttication signature flag of the attribute opcode is 0
//  X = 13 if authenttication signature flag of the attribute opcode is 1
//
// Authentication Signature
//

enum AttributeOpcode:UInt8 {
    case Unknown = 0x00
    case ErrorResponse        = 0x01
    case ExchangeMTURequest   = 0x02
    case ExchangeMTUResponse = 0x03
    case FindInformationRequest  = 0x04
    case FindInformationResponse = 0x05
    case FindByTypeValueRequest  = 0x06
    case FindByTypeValueResponse = 0x07
    case ReadByTypeRequest       = 0x08
    case ReadByTypeResponse      = 0x09
    case ReadRequest  = 0x0a
    case ReadResponse = 0x0b
    case ReadBlobRequest  = 0x0c
    case ReadBlobResponse = 0x0d
    case ReadMultipleRequest  = 0x0e
    case ReadMultipleResponse = 0x0f
    case ReadByGroupTypeRequest  = 0x10
    case ReadByGroupTypeResponse = 0x11
    case WriteRequest  = 0x12
    case WriteResponse = 0x13
    case WriteCommand  = 0x52
    case SignedWriteCommand = 0xD2
    case PrepareWriteRequest  = 0x16
    case PrepareWriteResponse = 0x17
    case ExecuteWriteRequest  = 0x18
    case ExecuteWriteResponse = 0x19
    case HandleValueNotification = 0x1B
    case HandleValueIndication   = 0x1D
    case HandleValueConfirmation = 0x1E
    
    func simpleDescription() -> String {
        switch self {
        case .Unknown: return "Unknown"
        case .ErrorResponse:           return "ErrorResponse"
        case .ExchangeMTURequest:      return "ExchangeMTURequest"
        case .ExchangeMTUResponse:     return "ExchangeMTUResponse"
        case .FindInformationRequest:  return "FindInformationRequest"
        case .FindInformationResponse: return "FindInformationResponse"
        case .FindByTypeValueRequest:  return "FindByTypeValueRequest"
        case .FindByTypeValueResponse: return "FindByTypeValueResponse"
        case .ReadByTypeRequest:  return "ReadByTypeRequest"
        case .ReadByTypeResponse: return "ReadByTypeResponse"
        case .ReadRequest:        return "ReadRequest"
        case .ReadResponse:       return "ReadResponse"
        case .ReadBlobRequest:    return "ReadBlobRequest"
        case .ReadBlobResponse:   return "ReadBlobResponse"
        case .ReadMultipleRequest:     return "ReadMultipleRequest"
        case .ReadMultipleResponse:    return "ReadMultipleResponse"
        case .ReadByGroupTypeRequest:  return "ReadByGroupTypeRequest"
        case .ReadByGroupTypeResponse: return "ReadByGroupTypeResponse"
        case .WriteRequest:         return "WriteRequest"
        case .WriteResponse:        return "WriteResponse"
        case .WriteCommand:         return "WriteCommand"
        case .SignedWriteCommand:   return "SignedWriteCommand"
        case .PrepareWriteRequest:  return "PrepareWriteRequest"
        case .PrepareWriteResponse: return "PrepareWriteResponse"
        case .ExecuteWriteRequest:  return "ExecuteWriteRequest"
        case .ExecuteWriteResponse: return "ExecuteWriteResponse"
        case .HandleValueNotification: return "HandleValueNotification"
        case .HandleValueIndication:   return "HandleValueIndication"
        case .HandleValueConfirmation: return "HandleValueConfirmation"
        }
    }
}

class AttributeProtocolPDUFactory {
    class func parseAttributeProtocolPDU(pdu:[UInt8]) -> AttributeProtocolPDU {
        let opcode = AttributeOpcode(rawValue: pdu[0])!
        switch opcode {
        case .ErrorResponse:          return AttributeErrorResponse(pdu:pdu)
        case .ExchangeMTURequest:     return AttributeExchangeMTURequest(pdu:pdu)
        case .ReadByGroupTypeRequest: return AttributeReadByGroupTypeRequest(pdu:pdu)
        case .ReadByTypeRequest:      return AttributeReadByTypeRequest(pdu:pdu)
        case .ReadRequest:            return AttributeReadRequest(pdu:pdu)
        case .FindInformationRequest: return AttributeFindInformationRequest(pdu:pdu)
        case .WriteRequest:           return AttributeWriteRequest(pdu:pdu)
        case .WriteCommand:           return AttributeWriteCommand(pdu:pdu)
        case .HandleValueConfirmation: return HandleValueConfirmation(pdu:pdu)
        default: return AttributeProtocolPDU(pdu:pdu)
        }
    }
}

class AttributeProtocolPDU {
    var Opcode:AttributeOpcode = .Unknown
    var Parameters:[UInt8] = []
    var AuthenticationSignature:[UInt8] = []
    
    var AuthenticationSignatureFlag:Bool = false
    var CommandFlag:Bool = false
    var Method:UInt8 = 0x00
    
    var PDU:[UInt8] {
        get {
            var pdu = [UInt8](count:1, repeatedValue:0)
            pdu[0] = Opcode.rawValue
            return pdu + Parameters + AuthenticationSignature
        }
    }
    
    init(opCode:AttributeOpcode) {
        self.Opcode = opCode
        
        let val = opCode.rawValue
        AuthenticationSignatureFlag = ((val & 0x80) != 0)
        CommandFlag = ((val & 0x40) != 0)
        Method = val & 0x1f
    }
    
    init(pdu:[UInt8]) {
        self.Opcode = AttributeOpcode(rawValue: pdu[0])!
        
        let val = pdu[0]
        AuthenticationSignatureFlag = ((val & 0x80) != 0)
        CommandFlag = ((val & 0x40) != 0)
        Method = val & 0x1f
        
        if AuthenticationSignatureFlag {
            Parameters = [UInt8](pdu[1..<(pdu.count - 12)])
            AuthenticationSignature = [UInt8](pdu[(pdu.count - 12)..<pdu.count])
        } else {
            Parameters = [UInt8](pdu[1..<(pdu.count)])
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
    
    func simpleDescription() -> String {
        return "Opcode:" + Opcode.simpleDescription() + " Parameters:" + self.arrayToString(Parameters) + " AuthenticationSignature:" + self.arrayToString(AuthenticationSignature)
    }
}

enum AttributeErrorCode:UInt8 {
    case InvalidHandle      = 0x01
    case ReadNotPermitted   = 0x02
    case WriteNotPermitted  = 0x03
    case InvalidPDU         = 0x04
    case InsufficientAuthentication = 0x05
    case RequestNotSupported = 0x06
    case InvalidOffset       = 0x07
    case InsufficientAuthorization = 0x08
    case PrepareQueueFull    = 0x09
    case AttributeNotFound   = 0x0A
    case AttributeNotLong    = 0x0B
    case InsufficientEncryptionKeySize = 0x0C
    case InvalidAttributeValueLength   = 0x0D
    case UnlikelyError = 0x0E
    case InsufficientEncryption = 0x0F
    case UnsupportedGroupType   = 0x10
    case InsufficientResources = 0x11
    
    func simpleDescription() -> String {
        switch self {
        case .InvalidHandle:    return "InvalidHandle"
        case .ReadNotPermitted: return "ReadNotPermitted"
        case .WriteNotPermitted: return "WriteNotPermitted"
        case .InvalidPDU: return "InvalidPDU"
        case .InsufficientAuthentication: return "InsufficientAuthentication"
        case .RequestNotSupported: return "RequestNotSupported"
        case .InvalidOffset: return "InvalidOffset"
        case .InsufficientAuthorization: return "InsufficientAuthorization"
        case .PrepareQueueFull: return "PrepareQueueFull"
        case .AttributeNotFound: return "AttributeNotFound"
        case .AttributeNotLong: return "AttributeNotLong"
        case .InsufficientEncryptionKeySize: return "InsufficientEncryptionKeySize"
        case .InvalidAttributeValueLength: return "InvalidAttributeValueLength"
        case .UnlikelyError: return "UnlikelyError"
        case .InsufficientEncryption: return "InsufficientEncryption"
        case .UnsupportedGroupType: return "UnsupportedGroupType"
        case .InsufficientResources: return "InsufficientResources"
        }
    }
}


class AttributeErrorResponse:AttributeProtocolPDU {
    var RequestOpcodeInError:AttributeOpcode = .ErrorResponse
    var AttributeHandleInError:UInt16 = 0x0000
    var ErrorCode:UInt8 = 0x0
    
    override init(pdu:[UInt8]) {
        super.init(pdu:pdu)
        
        RequestOpcodeInError   = AttributeOpcode(rawValue: Parameters[0])!
        AttributeHandleInError = UInt16(Parameters[1]) | UInt16(Parameters[2]) << 8
        ErrorCode = Parameters[3]
    }
    
    init(requestOpCodeInError:AttributeOpcode, attributeHandleInError:UInt16, errorCode:AttributeErrorCode) {
        super.init(opCode:.ErrorResponse)
        
        self.RequestOpcodeInError   = requestOpCodeInError
        self.AttributeHandleInError = attributeHandleInError
        self.ErrorCode              = errorCode.rawValue
        
        var pdu = [UInt8](count:4, repeatedValue:0)
        pdu[0] = RequestOpcodeInError.rawValue
        pdu[1] = UInt8(AttributeHandleInError & 0x00ff)
        pdu[2] = UInt8(AttributeHandleInError >> 8)
        pdu[3] = ErrorCode
        self.Parameters = pdu
    }
    
    func errorCodeToString(errorCode:UInt8) -> String {
        switch errorCode {
        case 0x01: return "Invalid Handle"
        case 0x02: return "Rad Not Permitted"
        case 0x03: return "Write Not Permitted"
        case 0x04: return "Invalid PDU"
        case 0x05: return "Insufficient Authentication"
        case 0x06: return "Request Not Supported"
        case 0x07: return "Invalid Offset"
        case 0x08: return "Insufficient Authorization"
        case 0x09: return "Prepare Queue Full"
        case 0x0A: return "Attribute Not Found"
        case 0x0B: return "Attribute Not Long"
        case 0x0C: return "Insufficient Encryption Key Size"
        case 0x0D: return "Invalid Attribute Value Length"
        case 0x0E: return "Unlikely Error"
        case 0x0F: return "Insufficient Encryption"
        case 0x10: return "Unsupported Group Type"
        case 0x11: return "Insufficient Resources"
        case 0x12...0x7F: return "Reserved"
        case 0x80...0x9f: return "Application Error"
        case 0xa0...0xdf: return "Reserved"
        case 0xe0...0xff: return "Common Profile and Service Error Code"
        default: return "Unknown"
        }
    }
    
    override func simpleDescription() -> String {
        let desc = super.simpleDescription()
        return desc
            + "\n\t" + "RequestOpcodeInError:" + RequestOpcodeInError.simpleDescription()
            + "\n\t" + String(format:"AttributeHandleInError:0x%04x", AttributeHandleInError)
            + "\n\t" + "ErrorCode:" + self.errorCodeToString(ErrorCode)
    }
}

class AttributeExchangeMTURequest:AttributeProtocolPDU {
    var ClientRXMTU:UInt16 = 0x0
    
    override init(pdu:[UInt8]) {
        super.init(pdu:pdu)
        ClientRXMTU = UInt16(Parameters[0]) | UInt16(Parameters[1]) << 8
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription() + "\n\t"
            + String(format:"ClientRXMTU:%d", ClientRXMTU)
    }
}

class AttributeExchangeMTUResponse:AttributeProtocolPDU {
    var ServerRxMTU:UInt16 = 0x0
    
    init(ServerRxMTU:UInt16) {
        super.init(opCode:.ExchangeMTUResponse)
        
        self.ServerRxMTU = ServerRxMTU
        self.Parameters  = [ UInt8(ServerRxMTU & 0x00ff), UInt8(ServerRxMTU >> 8)]
        self.AuthenticationSignature = []
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription() + "\n\t"
            + String(format:"ServierRxMTU:%d", ServerRxMTU)
    }
}

class AttributeReadByGroupTypeRequest:AttributeProtocolPDU {
    var StartingHandle:UInt16 = 0
    var EndingHandle:UInt16   = 0
    var AttributeType:BleUUID? = nil
    
    override init(pdu:[UInt8]) {
        super.init(pdu:pdu)
        StartingHandle = UInt16(Parameters[0]) | UInt16(Parameters[1]) << 8
        EndingHandle   = UInt16(Parameters[2]) | UInt16(Parameters[3]) << 8
        AttributeType  = BleUUID(uuid:([UInt8](Parameters[4..<Parameters.count])).reverse())
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\t" + String(format:"StartingHandle:0x%04x", StartingHandle)
            + "\n\t" + String(format:"EndingHandle:0x%04x", EndingHandle)
            + "\n\t" + "AttributeType:" + AttributeType!.simpleDescription()
    }
}

class AttributeReadByGroupTypeResponse:AttributeProtocolPDU {
    var AttributeHandle:UInt16 = 0
    var EndGroupHandle:UInt16  = 0
    var AttributeValue:[UInt8] = []
    
    init(AttributeHandle:UInt16, EndGroupHandle:UInt16, AttributeValue:[UInt8]) {
        super.init(opCode:.ReadByGroupTypeResponse)
        
        self.AttributeHandle = AttributeHandle
        self.EndGroupHandle  = EndGroupHandle
        self.AttributeValue  = AttributeValue
        self.Parameters = [UInt8(4 + AttributeValue.count),               // Length
            UInt8(AttributeHandle & 0x00ff), UInt8(AttributeHandle >> 8), // Attribute Handle
            UInt8(EndGroupHandle & 0x00ff), UInt8(EndGroupHandle >> 8), // EndGroup Handle
            ] + AttributeValue
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\t" + String(format:" AttributeHandle:0x%04x", AttributeHandle)
            + "\n\t" + String(format:" EndGroupHandle:0x%04x", EndGroupHandle)
            + "\n\t" + " AttributeValue:" + self.arrayToString(AttributeValue)
    }
}

class AttributeReadByTypeRequest:AttributeReadByGroupTypeRequest {}

class AttributeReadByTypeResponse:AttributeProtocolPDU {
    var AttributeHandle:UInt16 = 0
    var AttributeValue:[UInt8] = []
    
    init(AttributeHandle:UInt16, AttributeValue:[UInt8]) {
        super.init(opCode:.ReadByTypeResponse)
        
        self.AttributeHandle = AttributeHandle
        self.AttributeValue  = AttributeValue
        self.Parameters = [UInt8(2 + AttributeValue.count),               // Length
            UInt8(AttributeHandle & 0x00ff), UInt8(AttributeHandle >> 8), // Attribute Handle
            ] + AttributeValue
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\t" + String(format:" AttributeHandle:0x%04x", AttributeHandle)
            + "\n\t" + " AttributeValue:" + self.arrayToString(AttributeValue)
    }
}

class AttributeReadRequest : AttributeProtocolPDU {
    var AttributeHandle:UInt16 = 0
    
    override init(pdu:[UInt8]) {
        super.init(pdu:pdu)
        AttributeHandle = UInt16(Parameters[0]) | UInt16(Parameters[1]) << 8
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\t" + String(format:"AtrributeHandle:0x%04x", AttributeHandle)
    }
}

class AttributeReadResponse:AttributeProtocolPDU {
    var AttributeValue:[UInt8] = []
    
    init(AttributeValue:[UInt8]) {
        super.init(opCode:.ReadResponse)
        self.Parameters = AttributeValue
        
        self.AttributeValue  = AttributeValue
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\t" + " AttributeValue:" + self.arrayToString(AttributeValue)
    }
}

class AttributeWriteRequest : AttributeProtocolPDU {
    var AttributeHandle:UInt16 = 0
    var AttributeValue:[UInt8] = []

    override init(pdu:[UInt8]) {
        super.init(pdu:pdu)
        AttributeHandle = UInt16(Parameters[0]) | UInt16(Parameters[1]) << 8
        AttributeValue  = [UInt8](Parameters[2..<Parameters.count])
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\t" + String(format:"AtrributeHandle:0x%04x", AttributeHandle)
            + "\n\t" + "AtrributeValue:" + self.arrayToString(AttributeValue)
    }
}

class AttributeWriteResponse:AttributeProtocolPDU {
    init() {
        super.init(opCode:.WriteResponse)
    }
}

class AttributeWriteCommand : AttributeWriteRequest {
}

class AttributeFindInformationRequest: AttributeProtocolPDU {
    var StartingHandle:UInt16 = 0
    var EndingHandle:UInt16   = 0
    
    override init(pdu:[UInt8]) {
        super.init(pdu:pdu)
        StartingHandle = UInt16(Parameters[0]) | UInt16(Parameters[1]) << 8
        EndingHandle   = UInt16(Parameters[2]) | UInt16(Parameters[3]) << 8
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\t" + String(format:"StartingHandle:0x%04x", StartingHandle)
            + "\n\t" + String(format:"EndingHandle:0x%04x",   EndingHandle)
    }
}

enum FindInformationResponseFormat:UInt8 {
    case HandlesAnd16bitUUIDs  = 0x01
    case HandlesAnd128bitUUIDs = 0x02
    
    func simpleDescription() -> String {
        switch self {
        case .HandlesAnd16bitUUIDs: return  "HandlesAnd16bitUUIDs"
        case .HandlesAnd128bitUUIDs: return "HandlesAnd128bitUUIDs"
        }
    }
    
}

class AttributeFindInformationResponse: AttributeProtocolPDU {
    var Format:FindInformationResponseFormat = .HandlesAnd16bitUUIDs
    var InformationData:[UInt8] = []
    
    init(Format:FindInformationResponseFormat, InformationData:[UInt8]) {
        super.init(opCode:.FindInformationResponse)
        self.Format = Format
        self.InformationData = InformationData
        
        self.Parameters = [UInt8](count:1, repeatedValue:0)
        self.Parameters[0] = Format.rawValue
        self.Parameters += InformationData
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\t" + "Format:" + Format.simpleDescription()
            + "\n\t" + "InformationData:" + self.arrayToString(InformationData)
    }
}

class HandleValueNotification: AttributeProtocolPDU {
    var AttributeHandle:UInt16 = 0
    var AttributeValue:[UInt8] = []

    init(attributeHandle:UInt16, attributeValue:[UInt8]) {
        AttributeHandle = attributeHandle
        AttributeValue  = attributeValue

        super.init(opCode:.HandleValueNotification)
        
        var params = [UInt8](count:2, repeatedValue:0)
        params[0] = UInt8(AttributeHandle & 0x00ff)
        params[1] = UInt8(AttributeHandle >> 8)

        self.Parameters = params + AttributeValue
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\t" + String(format:" AttributeHandle:0x%04x", AttributeHandle)
            + "\n\t" + " AttributeValue:" + self.arrayToString(AttributeValue)
    }
}

class HandleValueIndication: AttributeProtocolPDU {
    var AttributeHandle:UInt16 = 0
    var AttributeValue:[UInt8] = []
    
    init(attributeHandle:UInt16, attributeValue:[UInt8]) {
        AttributeHandle = attributeHandle
        AttributeValue  = attributeValue

        super.init(opCode:.HandleValueIndication)
        
        var params = [UInt8](count:2, repeatedValue:0)
        params[0] = UInt8(AttributeHandle & 0x00ff)
        params[1] = UInt8(AttributeHandle >> 8)

        self.Parameters = params + AttributeValue
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\t" + String(format:" AttributeHandle:0x%04x", AttributeHandle)
            + "\n\t" + " AttributeValue:" + self.arrayToString(AttributeValue)
    }
}

class HandleValueConfirmation:AttributeProtocolPDU {
}
