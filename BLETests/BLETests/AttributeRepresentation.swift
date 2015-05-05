//
//  LogicalAttributeRepresentation.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/27.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

//BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part G] page 523
//2.5 ATTRIBUTE PROTOCOL

enum AttributeType:UInt16 {
    // service
    case PrimaryService   = 0x2800
    case SecondaryService = 0x2801
    case Include          = 0x2802
    case Characteristic   = 0x2803
    case CharacteristicExtendedProperties  = 0x2900
    case CharacteristicUserDescription     = 0x2901
    case ClientCharacteristicConfiguration = 0x2902
    case ServerCharacteristicConfiguration = 0x2903
    case CharacteristicFormat              = 0x2904
    case CharacteristicAggregateFormat     = 0x2905
    
    func simpleDescription() -> String {
        switch self {
        case .PrimaryService:   return "PrimaryService"
        case .SecondaryService: return "SecondaryService"
        case .Include:          return "Include"
        case .Characteristic:   return "Characteristic"
        case .CharacteristicExtendedProperties:  return "CharacteristicExtendedProperties"
        case .CharacteristicUserDescription:     return "CharacteristicUserDescription"
        case .ClientCharacteristicConfiguration: return "ClientCharacteristicConfiguration"
        case .ServerCharacteristicConfiguration: return "ServerCharacteristicConfiguration"
        case .CharacteristicFormat:              return "CharacteristicFormat"
        case .CharacteristicAggregateFormat:     return "CharacteristicAggregateFormat"
        }
    }
}

class AttributeRepresentation {
    var Handle:UInt16       = 0
    var Type:BleUUID?       = nil
    var Value:[UInt8]       = []
    var Permissions:[UInt8] = []
    
    var _desc = ""
    
    // Logical attribute representationのバイト配列
    var Data:[UInt8] {
        get {
            return [UInt8(Handle & 0x00ff), UInt8(Handle >> 8)] + Type!.Bytes.reverse() + Value
        }
    }
    
    init(handle:UInt16, type:BleUUID, value:[UInt8]) {
        self.Handle = handle
        self.Type   = type
        self.Value  = value
        
        _desc = String(format:"Handle:0x%04x", Handle)
            + " Type:"  + type.simpleDescription()
            + " Value:" + self.arrayToString(Value)
    }
    
    init(handle:UInt16, type:AttributeType, value:[UInt8]) {
        self.Handle = handle
        self.Type   = BleUUID(bluetoothUUID: type.rawValue)
        self.Value  = value
        
        _desc = String(format:"Handle:0x%04x", Handle)
            + " Type:"  + type.simpleDescription()
            + " Value:" + self.arrayToString(Value)
    }
    
    func arrayToString(packet:[UInt8]) -> String {
        var str = "["
        for val in packet {
            str += String(format:"0x%02x, ", val)
        }
        str += "]"
        
        return str
    }
    
    func simpleDescription() -> String {
        return _desc
    }
}

class PrimaryServiceAttribute:AttributeRepresentation {
    init(handle:UInt16, uuid:BleUUID) {
        super.init(handle:handle, type:.PrimaryService, value:uuid.Bytes.reverse())
    }
}

enum CharacteristicProperty:UInt8 {
    case Broadcast = 0x01
    case Read      = 0x02
    case WriteWithoutResponse = 0x04
    case Write     = 0x08
    case Notify    = 0x10
    case Indicate  = 0x20
    case AuthenticatedSignedWrites = 0x40
    case ExtendedProperties        = 0x80
    
    func simpleDescription() -> String {
        switch self {
        case .Broadcast: return "Broadcast"
        case .Read:      return "Read"
        case .WriteWithoutResponse: return "WriteWithoutResponse"
        case .Write:    return "Write"
        case .Notify:   return "Notify"
        case .Indicate: return "Indicate"
        case .AuthenticatedSignedWrites: return "AuthenticatedSignedWrites"
        case .ExtendedProperties: return "ExtendedProperties"
        }
    }
}

class CharacteristicDeclarationAttribute:AttributeRepresentation {
    var CharacteristicProperties:[CharacteristicProperty] = []
    var CharacteristicValueHandle:UInt16 = 0
    var CharacteristicUUID:BleUUID?      = nil
    
    init(handle:UInt16, properties:[CharacteristicProperty], valueHandle:UInt16, uuid:BleUUID) {
        var data = [UInt8](count:3, repeatedValue:0)
        for property in properties {
            data[0] |= property.rawValue
        }
        data[1] = UInt8(valueHandle & 0x00ff)
        data[2] = UInt8(valueHandle >> 8)
        data += uuid.Bytes.reverse()
        
        super.init(handle:handle, type:.Characteristic, value: data)
        
        CharacteristicProperties  = properties
        CharacteristicValueHandle = valueHandle
        CharacteristicUUID        = uuid
    }
    
    override func simpleDescription() -> String {
        var propertyDesc = ""
        for property in CharacteristicProperties {
            propertyDesc += property.simpleDescription() + ","
        }
        
        return super.simpleDescription()
            + "\n\t Properties:" + propertyDesc
            + String(format:"\n\t ValueHandle:0x%04x", CharacteristicValueHandle)
            + "\n\t CharacteristicUUID:" + CharacteristicUUID!.simpleDescription()
    }
}

class CharacteristicValueDeclarationAttribute:AttributeRepresentation {
    init(handle:UInt16, characteristicUUID:BleUUID, value:[UInt8]) {
        super.init(handle:handle, type:characteristicUUID, value:value)
    }
}

enum CharacteristicConfigurationBits:UInt16 {
    case Notification = 0x0001
    case Indication   = 0x0002
    
    func simpleDescription() -> String {
        switch self {
        case .Notification: return "Notification"
        case .Indication: return "Indication"
        }
    }
}

class ClientCharactristicConfigurationAttribute:AttributeRepresentation {
    var CharacteristicConfigurations:[CharacteristicConfigurationBits] = []
    var _Value:[UInt8] = []
    
    override var Value:[UInt8] {
        get {
            return _Value
        }
        set(newValue) {
            // ビット配列を更新
            var val = UInt16(newValue[0]) | UInt16(newValue[1]) << 8
            var bits:[CharacteristicConfigurationBits] = []
            for bit:CharacteristicConfigurationBits in [.Notification, .Indication] {
                if (bit.rawValue & val) != 0 {
                    bits.append(bit)
                }
            }
            CharacteristicConfigurations = bits
        }
    }
    
    init(handle:UInt16, CharacteristicConfigurations:[CharacteristicConfigurationBits]) {
        self.CharacteristicConfigurations = CharacteristicConfigurations
        
        var val = UInt16(0)
        for cfg in CharacteristicConfigurations {
            val |= cfg.rawValue
        }
        super.init(handle:handle, type:.ClientCharacteristicConfiguration, value:[UInt8(val & 0x00ff), UInt8(val >> 8)])
    }
    
    override func simpleDescription() -> String {
        var cfgDesc = ""
        for cfg in CharacteristicConfigurations {
            cfgDesc += cfg.simpleDescription() + ","
        }
        
        return super.simpleDescription()
            + "\n\t CharacteristicConfigurations:" + cfgDesc
    }
}

class CharactristicPresentationFormatAttribute:AttributeRepresentation {
    var Format:UInt8       = 0
    var Exponent:UInt8     = 0
    var Unit:UInt16        = 0
    var NameSpace:UInt8    = 0
    var Description:UInt16 = 0
    
    init(handle:UInt16, format:UInt8, exponent:UInt8, unit:UInt16, nameSpace:UInt8, description:UInt16) {
        self.Format      = format
        self.Exponent    = exponent
        self.Unit        = unit
        self.NameSpace   = nameSpace
        self.Description = description
        
        var val = [UInt8](count:7, repeatedValue:0)
        val[0] = Format
        val[1] = Exponent
        val[2] = UInt8(Unit & 0x00ff)
        val[3] = UInt8(Unit >> 8)
        val[4] = NameSpace
        val[5] = UInt8(Description & 0x00ff)
        val[6] = UInt8(Description >> 8)
        
        super.init(handle:handle, type:.CharacteristicFormat, value:val)
    }
    
    override func simpleDescription() -> String {
        return super.simpleDescription()
            + "\n\t" + String(format:"Format:0x%02x",  Format)
            + "\n\t" + String(format:"Exponent:%d",    Exponent )
            + "\n\t" + String(format:"Unit:%d",        Unit)
            + "\n\t" + String(format:"NameSpace:%d",   NameSpace)
            + "\n\t" + String(format:"Description:%d", Description)
    }
}
