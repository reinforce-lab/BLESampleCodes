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
        if adaptor == nil {
            println("No USB Bluetooth dongle is found.");
            return
        }

        // 製品名を出力します。
        println("Product name:\(adaptor!.productName)")
    }
}

