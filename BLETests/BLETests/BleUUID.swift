//
//  bleUUID.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/27.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

func == (left:BleUUID, right:BleUUID) -> Bool {
    return left.Bytes == right.Bytes
}

func != (left:BleUUID, right:BleUUID) -> Bool {
    return left.Bytes != right.Bytes
}

class BleUUID {
    var _description:String = ""
    
    // bytes representation
    var Bytes:[UInt8] = []
    
    // 16-bit UUID?
    var IsBluetoothUUID:Bool {
        get {
            return Bytes.count == 2
        }
    }
    
    init(bluetoothUUID:UInt16) {
        Bytes = [ UInt8(bluetoothUUID >> 8 ), UInt8(bluetoothUUID & 0x00ff )]
        _description = String(format:"0x%04x", bluetoothUUID)
    }
    
    init(uuid:String) {
        Bytes = [UInt8](count:16, repeatedValue:0)
        let nsuuid = NSUUID(UUIDString: uuid)
        nsuuid!.getUUIDBytes(&Bytes)
        _description = nsuuid!.UUIDString
    }
    
    init(uuid:[UInt8]) {
        if uuid.count == 2 {
            Bytes        = uuid
            _description = String(format:"0x%04x", UInt16(uuid[0]) << 8 | UInt16(uuid[1]))
        } else {
            Bytes = [UInt8](count:16, repeatedValue:0)
            let nsuuid = NSUUID(UUIDBytes: uuid)
            nsuuid.getUUIDBytes(&Bytes)
            _description = nsuuid.UUIDString
        }
    }
    
    func simpleDescription() -> String {
        return _description
    }
}
