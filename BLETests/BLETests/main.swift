//
//  main.swift
//  testusb
//
//  Created by AkihiroUehara on 2015/03/31.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// USBAdaptorTest
// USB Bluetoothドングルの接続確認。
/*
let test = USBAdaptorTest()
test.test()
*/
/*
let adaptor = BluetoothUSBAdaptor()
let socket = HCISocket(adaptor:adaptor)
let (eventCode, parameters) = socket.sendCommand(.Reset, parameters:[])
println("eventCode:\(eventCode.simpleDescription()) parameters:\(parameters)")
*/

/*
let test = AdvertisingTest()
test.test()
*/

/*
let test = ConnectionTest()
test.test()
*/

/*
let test = BatteryLevelServiceTest()
test.test()
*/


let test = ParingAndBondingTest()
test.test()


/*
let sm = SecurityManager()
sm.test_c1()
sm.test_s1()
*/