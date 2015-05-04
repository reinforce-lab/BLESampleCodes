//
//  File.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/27.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

class GATTServer {
    var Database:[AttributeRepresentation] = []
    
    init() {}
    
    init(database:[AttributeRepresentation]) {
        self.Database = database
    }
    
    // Public methods
    func readByGroupType(startingHandle:UInt16, endingHandle:UInt16, attributeType:BleUUID) -> [AttributeRepresentation] {
        return Database.filter( {(value:AttributeRepresentation) -> Bool in
            return (startingHandle <= value.Handle && value.Handle  <= endingHandle && value.Type! == attributeType)
        })
    }
    
    func findAttributes(startingHandle:UInt16, endingHandle:UInt16) -> [AttributeRepresentation] {
        return Database.filter( {(value:AttributeRepresentation) -> Bool in
            return (startingHandle <= value.Handle && value.Handle  <= endingHandle)
        })
    }
    
    // ハンドルでAttributeを取得します
    func findAttribute(handle:UInt16) -> AttributeRepresentation? {
        let attrs = Database.filter( {(value:AttributeRepresentation) -> Bool in
            return value.Handle == handle
        })
        return (attrs.count == 0) ? nil : attrs[0]
    }
    
    // サービスのstart/endハンドルレンジを変えします
    func getServiceHandleRange(serviceAttribute:AttributeRepresentation) ->(startingHandle:UInt16, endingHandle:UInt16) {
        var startingHandle = serviceAttribute.Handle
        // 次のサービスのハンドラを探す
        var serviceFound = false
        var endingHandle = UInt16(0xffff)
        for attr in Database {
            if serviceFound {
                if attr.Type! == serviceAttribute.Type! {
                    break
                }
                endingHandle = attr.Handle                
            } else {
                serviceFound = (attr.Handle == startingHandle)
            }
        }
        return (startingHandle, endingHandle)
    }
    
    func simpleDescription() -> String {
        var desc = ""
        for attr in Database {
            desc += attr.simpleDescription()
        }
        return desc
    }
}



// 128-bit UUIDを使った、カスタムなサービスとキャラクタリスティクス
class CustomGATTServer:SimpleGATTServer {
    
    override init() {
        super.init()
        self.Database += [
            // Custom service
            PrimaryServiceAttribute(handle: 0x0020, uuid:BleUUID(uuid: "00C5E2A5-545A-4402-862E-EAA09D4C04D1")),
            CharacteristicDeclarationAttribute(handle: 0x0021, properties: [.Read, .Notify, .Indicate], valueHandle: 0x0022, uuid: BleUUID(uuid:"01C5E2A5-545A-4402-862E-EAA09D4C04D1")),
            CharacteristicValueDeclarationAttribute(handle: 0x0022, characteristicUUID: BleUUID(uuid:"01C5E2A5-545A-4402-862E-EAA09D4C04D1"), value: [0x00]),
            CharactristicPresentationFormatAttribute(handle: 0x0023,
                format: 0x04, // unsigned int8
                exponent: 0,
                unit: 0x27ad, //0x27AD	percentage	org.bluetooth.unit.percentage, see https://developer.bluetooth.org/gatt/units/Pages/default.aspx
                nameSpace: 0x01, // Bluetooth SIG Assigned Numbers
                description: 0x00),
            ClientCharactristicConfigurationAttribute(handle: 0x0024, CharacteristicConfigurations: []),
            //
        ]
        
        
    }
}
