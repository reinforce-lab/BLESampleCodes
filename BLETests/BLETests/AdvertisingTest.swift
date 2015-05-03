//
//  hoge.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/17.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

class AdvertisingTest:TestBase {
    
    func test() -> () {
        var event:HCIEvent;
        
        // リセットコマンド
        event = self.sendCommand(.Reset, parameters:[])
        if event.eventCode != .CommandCompleted {
            return
        }

        // BD_ADDR の読み出し
        event = self.sendCommand(.ReadBD_ADDR, parameters:[])
        if event.eventCode != .CommandCompleted {
            return
        }
        let BD_ADDR = event.parameters[1..<event.parameters.count].reverse()
        println(" BD_ADDR:\(BD_ADDR).")

        //イベントマスクを設定
        //0x2000000000000000 LE Meta-Event
        event = self.sendCommand(.SetEventMask, parameters:[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20 ])
        // LEメタイベントを設定
        //0x000000000000001F Default
        event = self.sendCommand(.LESetEventMask, parameters:[0x1F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ])

        // アドバタイジングを開始する
        event = self.sendCommand(.LESetAdvertisingData, parameters:[
            /*
            // 最も短いアドバタイジング・データの例。Flagsは必ず指定しなければならないフィールド。
            0x03, // Advertising_Data_Length 
            
            // Advertising Data
            
            // AD type Flags(0x01), 0x01 | 0x02
            //  LE General Discoverable Mode 0x01
            //  BR/EDR Not Supported         0x02
            0x02, 0x01, 0x05,
            // アドバタイジング・データは31オクテットの長さがなければならない。無効データ領域は0フィルして与える。
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
            */
            
            // 一般的なアドバタイジング・データの例。
            0x10, // Advertising_Data_Length, 3 + 9 + 4 = 16
            // Advertising data
            // Length(1), AD type(1), AD Data(length -1)

            // AD type Flags(0x01), 0x01 | 0x02
            //  LE General Discoverable Mode 0x01
            //  BR/EDR Not Supported         0x02
            0x02, 0x01, 0x03,
            
            // Shortened Local Name (0x08), Complete Local Name (0x09)
            //  UTF-8 text (TESTDEV)
            0x08, 0x09, 0x54, 0x45, 0x53, 0x54, 0x44, 0x45, 0x56,

            // Incomplete List of 16-bit Service Class UUIDs (0x02)
            //  UUID 0x12, 0x34
            0x03, 0x02, 0x12, 0x34,
            
            // 31 - 16 = 15
            0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00
            ])
        
        event = self.sendCommand(.LESetAdvertisingParameters, parameters:[
            0x30, 0x00, //Addvertisiong_Interval_Min:    0x0030 (30ミリ秒)
            0x00, 0x08, // Advertising_Interval_Max:     0x0800 (1.28sec)
            0x00, // Advertisiong_type: 0x00 Connectable undirected advertisiong ADV_IND
            
            0x00, // Own_Address_type:  Public Device Address (default)
            0x00, // Peer_Address_type: Public Device Address
            
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Peer_adddress
            0x07, // Advertising_Channel_Map: all channels enabled
            0x00  // Advertisiong_Filter_Policy: Process scan and connection requests from all devices.
            ])
        
        event = self.sendCommand(.LESetAdvertiseEnable, parameters: [0x01])
    }
    
}