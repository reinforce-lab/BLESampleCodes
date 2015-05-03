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

// GAPのみの、最も単純なGATTサーバ
class SimpleGATTServer:GATTServer {
    override init() {
        super.init()
        
        self.Database = [
            // GATT Service (Generic Access Profile)
            // see https://developer.bluetooth.org/gatt/services/Pages/ServiceViewer.aspx?u=org.bluetooth.service.generic_access.xml
            PrimaryServiceAttribute(handle: 0x0001, uuid:BleUUID(bluetoothUUID: 0x1800)),
            // Device Name, Mandatory
            CharacteristicDeclarationAttribute(handle: 0x0002, properties:[.Read], valueHandle: 0x0003, uuid: BleUUID(bluetoothUUID: 0x2a00)),
            // value:UTF-8 text (TESTDEV-1), アドバタイジングでは、shortened local name として"TESTDEV"を送信しています。ここでは完全な名前を送信しています。
            // ほとんどの値が単1のIntなので、PDUにはリトル・エンディアンに変換しています。ですが、これではテキストは逆順になってしまうので、テキストだけはここで逆順にして格納しています
            CharacteristicValueDeclarationAttribute(handle: 0x003, characteristicUUID: BleUUID(bluetoothUUID: 0x2a00), value:[0x54, 0x45, 0x53, 0x54, 0x44, 0x45, 0x56, 0x5f, 0x31] ),
            // Appearance, Mandatory
            CharacteristicDeclarationAttribute(handle: 0x0004, properties:[.Read], valueHandle: 0x0005, uuid: BleUUID(bluetoothUUID: 0x2a01)),
            // value:unknown category (10-bit 0x00), sub-category (6-bit 0x00)
            CharacteristicValueDeclarationAttribute(handle: 0x005, characteristicUUID: BleUUID(bluetoothUUID: 0x2a01), value:[0x00]),
        ]
    }
}

// バッテリーレベルのサービスをもつGATTサーバ
class BatteryLevelGATTServer:SimpleGATTServer {
    
    override init() {
        super.init()
        self.Database += [
            // Battery level
            // https://developer.bluetooth.org/gatt/services/Pages/ServiceViewer.aspx?u=org.bluetooth.service.battery_service.xml
            PrimaryServiceAttribute(handle: 0x0010, uuid:BleUUID(bluetoothUUID: 0x180F)),
            // Battery level
            CharacteristicDeclarationAttribute(handle: 0x0011, properties:[.Read, .Notify], valueHandle: 0x0012, uuid: BleUUID(bluetoothUUID: 0x2a19)),
            CharacteristicValueDeclarationAttribute(handle:  0x0012, characteristicUUID: BleUUID(bluetoothUUID: 0x2a19), value:[UInt8(100)] ),
            CharactristicPresentationFormatAttribute(handle: 0x0013,
                format: 0x04,    // unsigned int8
                exponent: 0,
                unit: 0x27ad,    //0x27AD	percentage	org.bluetooth.unit.percentage, see https://developer.bluetooth.org/gatt/units/Pages/default.aspx
                nameSpace: 0x01, // Bluetooth SIG Assigned Numbers
                description: 0x00),
            ClientCharactristicConfigurationAttribute(handle: 0x0014, CharacteristicConfigurations: []),
        ]
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
