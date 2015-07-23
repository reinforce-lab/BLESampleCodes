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
    let _socket:HCISocket
    
    init() {
        _adaptor = BluetoothUSBAdaptor()
        _socket  = HCISocket(adaptor:_adaptor)
    }
    
    // HCIコマンド送信ファンクション。
    // 詳細をデバッグコンソールに出力します。
    func sendCommand(command:HCIOpcodeCommand, parameters:[UInt8]) -> (HCIEvent){
        let event = _socket.sendCommand(command, parameters:parameters)
        println("command:\(command.simpleDescription()) parameters:\(parameters) -> \(event.simpleDescription())")
        return event
    }
    
    // Objective-Cの @synchoronized 相当のメソッド。
    // ref http://stackoverflow.com/questions/24045895/what-is-the-swift-equivalent-to-objective-cs-synchronized
    func synchronized(lock: AnyObject!, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }

    // テストの実行本体メソッド。
    func test() -> () {}
}