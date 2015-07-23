//
//  main.swift
//  testusb
//
//  Created by AkihiroUehara on 2015/03/31.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

// Test 01
// USB Bluetoothドングルの接続確認です。
/*
let test = USBAdaptorTest()
test.test()
*/


// Test 02
// アドバタイジングを開始します。
let test = AdvertisingTest()
test.test()


/*
let test = ConnectionTest()
test.test()
*/

/*
let test = BatteryLevelServiceTest()
test.test()
*/

/*
let test = ParingTest()
test.test()
*/

/*
let sm = SecurityManager()
sm.test_c1()
sm.test_s1()
*/