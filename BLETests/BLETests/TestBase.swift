//
//  File.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/23.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// テストのベースクラス
class TestBase {
    let _adaptor:BluetoothUSBAdaptor
//    let _adaptor:libUSBWrapper
    let _socket:HCISocket
    
    init() {
        _adaptor = BluetoothUSBAdaptor()
//        _adaptor = libUSBWrapper()
        _socket  = HCISocket(adaptor:_adaptor)

    }
    
    // 説明付きの、HCIコマンド送信ファンクション
    func sendCommand(command:HCIOpcodeCommand, parameters:[UInt8]) -> (HCIEvent){
        let event = _socket.sendCommand(command, parameters:parameters)
        println("command:\(command.simpleDescription()) parameters:\(parameters) -> \(event.simpleDescription())")
        return event
    }
}