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


