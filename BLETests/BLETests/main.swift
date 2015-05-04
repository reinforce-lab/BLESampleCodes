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

let test = BatteryLevelServiceTest()
test.test()


/*


let wrapper = libUSBWrapper()
let result  = wrapper.open(0x0a12, productID: 0x01)
println("result \(result)")

var packet = [0x03, 0x0c, 0x00]
//let code = libusb_error.LIBUSB_SUCCESS

wrapper.sendCommand(
packet,
completed:{(result : libusb_error) in
println("result \(result)")
})

wrapper.receiveEvent() {
(array: [AnyObject]!, int errorCode) in
println("received: \(array)")
}

*/