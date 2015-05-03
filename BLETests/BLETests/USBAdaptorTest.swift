//
//  main.swift
//
//  Created by AkihiroUehara on 2015/03/31.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

class USBAdaptorTest {
    func test() {
        // Bluetooth USB ドングルの接続確認をします
        
        // USBドングルとのやりとりをするBluetoothUSBAdasptorのインスタンスを生成します。
        // もしもUSBドングルが見つからなければ、nilが返されます。
        let adaptor = BluetoothUSBAdaptor()
        
        println("Product name:\(adaptor?.productName)")
        
        // アダプタにリセットコマンドを送ります。
        var packet:[UInt8] = [0x03, 0x0c, 0x00]
        var result = adaptor.executeCommand(NSData(bytes:packet, length:packet.count))
        
        // コマンドの結果を受け取ります。
        var buffer = [UInt8](count: result.length, repeatedValue:0)
        result.getBytes(&buffer, length:result.length)
        println("result:\(buffer)")
    }
}

