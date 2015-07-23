//
//  hoge.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/04/17.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation

class AdvertisingTest:TestBase {
    override func test() -> () {
        var event:HCIEvent;
        
        // Bluetooth USBドングルに、リセットコマンドを送ってリセットします。
        event = self.sendCommand(.Reset, parameters:[])
        if event.eventCode != .CommandCompleted {
            return
        }

        // BD_ADDR を読み出します。
        event = self.sendCommand(.ReadBD_ADDR, parameters:[])
        if event.eventCode != .CommandCompleted {
            return
        }
        let BD_ADDR = event.parameters[1..<event.parameters.count].reverse()
        println(" BD_ADDR:\(BD_ADDR).")

        // イベントマスクを設定します。受け取るイベントは、ビット・マスクを明示的に指定しないと、発生したイベントが受け取れません。
        //0x2000000000000000 LE Meta-Event, LE関連のイベントのみを受け取るようにします。
        // イベントとビットの対応の詳細は、以下を参照してください。
        // BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 642
        // 7.3.1 Set Event Mask Command
        event = self.sendCommand(.SetEventMask, parameters:[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20 ])

        // LEメタイベントを設定します。
        // LE関連のイベントは、BluetoothのLEイベントのさらにサブイベントとして通知されます。
        // どのサブイベントを受け取るか、ビット・マスクを明示的に指定しないと、発生したイベントが受け取れません。
        // 0x000000000000001F Default, すべてのイベントを受け取るようにします
        // BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 962
        // 7.8.1 LE Set Event Mask Command
        event = self.sendCommand(.LESetEventMask, parameters:[0x1F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ])

        // アドバタイジングを開始する
        event = self.sendCommand(.LESetAdvertisingData, parameters:[
            /*
            // 最も短いアドバタイジング・データの例。
            // どのような場合でも、アドバタイジング・データには必ずFlagsフィールドを含まなければなりません。

            // Advertising_Data_Length
            // アドバタイジング・データの長さ示す1オクテットのフィールドです。
            0x03,
            
            // AD type Flags(0x01)
            //  LE General Discoverable Mode 0x02
            //  BR/EDR Not Supported         0x04
            0x02, 0x01, 0x06,
            */
            
            // 一般的なアドバタイジング・データの例。

            // アドバタイジング・データの長さ示す1オクテットのフィールドです。アドバタイジング・データは最大31オクテット( 0x1f )です。
            // Advertising_Data_Length, 3 + 9 + 4 = 16
            0x10,

            // アドバタイジング・データは複数のAD Structure を含みます。
            // AD Structure は、1オクテットのLength、にLengthオクテットのDataを含みます。Dataは先頭1オクテットの AD Type と(Length -1)オクテットのAD Dataを含みます。
            
            // アドバタイジング・データのフィールドの詳細は、Bluetoothの仕様書本体ではなく、補綴の資料のなかで提供されています。
            // アドバタイジングのFlagsの詳細は、以下にあります。
            // Supplement to Bluetooth Core Specification page 12 of 37
            // 1.3 FLAGS

            // AD type Flags(0x01)
            //  LE General Discoverable Mode 0x02
            //  BR/EDR Not Supported         0x04
            // このデータ配列の意味は、先頭から、Length が 0x02(2オクテット)、AD Type が 0x01 (AD type Flags)、 値が 0x06(LE General Discoverable mode, BR/EDR not supported)です。
            0x02, 0x01, 0x06,
            
            // アドバタイジングしている装置名を、UTF-8で符号化したテキストデータで表します。
            // AD Typeは、装置名がアドバタイジング・データに完全に収まるときは Complete Local Name(0x09)を、完全な装置名の先頭部分だけを含むときはShortened Local Name(0x08)を使います。
            // Shortened Local Nameのときは、接続後にセントラルが、装置のGAPサービスのローカル名を読みだして、完全なローカル名に更新します。
            // AD Dataは終端記号を含まないテキストデータです。C言語でよくある 0x00で文字列終端を表す必要はありません。

            // Shortened Local Name (0x08), Complete Local Name (0x09)
            // UTF-8 text (TESTDEV)
            0x08, 0x09, 0x54, 0x45, 0x53, 0x54, 0x44, 0x45, 0x56,

            // アドバタイジング・パケットは、その装置に含まれるサービスの一覧を含みます。
            // サービスは、16-bit, 32-bit, そして128-bitの3つの長さがあります。129-bitのサービスは1つしか収まらないので、たいていはアドバタイジング・データではなく、スキャンレスポンス・データに入れます。
            // Incomplete List of 16-bit Service Class UUIDs (0x02)
            // UUID 0x12, 0x34
            0x03, 0x02, 0x12, 0x34,

            // HCIでアドバタイジング・データを設定するときは、配列長が31バイトになるようにパッディングを入れます。
            // HCIで31バイトではないバイト配列を渡すと、コントローラはアドバタイジング・データを設定してくれません。
            // 31 - 16 = 15
            0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00
            ])
        
        event = self.sendCommand(.LESetAdvertisingParameters, parameters:[
            // アドバタイジングを開始します。
            // パラメータの詳細は、以下にあります。
            // BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 968
            // 7.8.5 LE Set Advertising Parameters Command
            
            // エンディアンは、リトル・エンディアンです。例えば、16-bit符号なし整数 0x0001 ならば、[0x01, 0x00] と最下位バイトが先頭に、最上位バイトが末尾に置かれます。
            //Addvertisiong_Interval_Min:    0x0030 (30ミリ秒)
            0x30, 0x00,
            // Advertising_Interval_Max:     0x0800 (1.28sec)
            0x00, 0x08,
            // Advertisiong_type: 0x00 Connectable undirected advertisiong ADV_IND
            0x00,
            
            // Own_Address_type:  Public Device Address (default)
            0x00,
            // Peer_Address_type: Public Device Address
            0x00,
            
            // Peer_adddress
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            // Advertising_Channel_Map: all channels enabled
            0x07,
            // Advertisiong_Filter_Policy: Process scan and connection requests from all devices.
            0x00
            ])
        
        event = self.sendCommand(.LESetAdvertiseEnable, parameters: [0x01])
    }
    
}