//
//  SecurityManager.swift
//  BLETests
//
//  Created by AkihiroUehara on 2015/05/06.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

import Foundation
//import RNCryptor

// 任意長整数は[UInt8]として処理します。Bluetooth仕様書の表記に合わせて、演算子をオーバーロードします。
// ビット連結演算子
func || (left:[UInt8], right:[UInt8]) -> [UInt8] {
    return left + right
}
// XOR演算子
func ^ (left:[UInt8], right:[UInt8]) -> [UInt8] {
    var result = [UInt8](count:left.count, repeatedValue:0)
    for i in 0..<left.count {
        result[i] = left[i] ^ right[i]
    }
    return result
}

// BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 587
// Security Manager Specification

class SecurityManager {
    // BLUETOOTH SPECIFICATION Version 4.2 [Vol 2, Part E] page 970
    // Host Controller Interface Functional Specification
    
    var initiatorAddressType:UInt8  = 0
    var initiatorAddress:[UInt8]    = []
    var respondingDeviceAddressType:UInt8 = 0
    var respondingDeviceAddress:[UInt8]   = []
    
    var pairingRequest:PairingRequest?   = nil
    var pairingResponse:PairingResponse? = nil
    var mPairingConfirm:[UInt8] = []
    var mPairingRandom:[UInt8]  = []
    
//    var sPairingRandom:[UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10]
    var sPairingRandom:[UInt8] = [UInt8](count:16, repeatedValue:0)
    
    var DiversifierHidingKey:[UInt8] = [UInt8](count:16, repeatedValue:0)
    var EncryptionRootKey:[UInt8]    = [UInt8](count:16, repeatedValue:0)
    var IdentityRootKey:[UInt8]      = [UInt8](count:16, repeatedValue:0)
    
    // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 613
    // 2.3.5.5 LE Legacy Pairing Phase 2
    func getSConfirmValue() -> [UInt8] {
        //Srand tk = 0x00
        //Sconfirm = c1(TK, Srand, Pairing Request command, Pairing Response command, initiating device address type, initiating device address, responding device address type, responding device address)
        let confirmValue = self.c1(
            [UInt8](count:16, repeatedValue:0),
            r:sPairingRandom,
            preq:(pairingRequest!.PDU).reverse(),
            pres:(pairingResponse!.PDU).reverse(),
            iat:initiatorAddressType,
            rat:respondingDeviceAddressType,
            ia:initiatorAddress,
            ra:respondingDeviceAddress
        )
        return confirmValue
    }

    // masterのconfirm valueをデコードして、期待値かを確認します。
    func isValidMConfirmValue(mConfirmValue:[UInt8], pairingRandom:[UInt8]) -> Bool {
//        let p1 = pres || preq || [rat] || [iat]
        let k  = [UInt8](count:16, repeatedValue:0)
        let p2 = [UInt8](count:(32 / 8), repeatedValue:0) || initiatorAddress || respondingDeviceAddress
        let v1 = self.decrypt(k, encryptedText:mConfirmValue)
        // v1 is plainText:self.e(k, plainText: r ^ p1) ^ p2
        let v2 = self.decrypt(k, encryptedText:(v1 ^ p2))
        // r ^ p1
        let p1 = v2 ^ pairingRandom
//        println("p1:\(p1)")
//        let p1 = pres || preq || [rat] || [iat]
        let expectedValue = (pairingResponse!.PDU).reverse() || (pairingRequest!.PDU).reverse() || [respondingDeviceAddressType] || [initiatorAddressType]        
        return p1 == expectedValue
    }

    // STK = s1(TK, Srand, Mrand)
    func getShortTermKey() -> [UInt8] {
        return self.s1([UInt8](count:16, repeatedValue:0), // TK
            r1:sPairingRandom,
            r2:mPairingRandom
        )
    }
    
    // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 658
    // B.2.2 Generating Keys from ER
    // LTK = d1(ER, DIV, 0), 
    // DIV(Diversifier), 16-bit value
    func getLongTermKey(diversifier:[UInt8]) -> [UInt8] {
        return self.d1(EncryptionRootKey, d:diversifier, r:[UInt8](count:2, repeatedValue:0))
    }
    
    // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 655
    // A.1.2 EDIV Generation
    // diversifier, 16-bit value
    // rand: 64-bit value
    func getEDIV(diversifier:[UInt8], rand:[UInt8]) -> [UInt8] {
        let y    = self.dm(DiversifierHidingKey, r:rand)
        let ediv = y ^ diversifier
        return ediv
    }
    
    // diversifier, 16-bit value
    // rand: 64-bit value
    func getDIV(ediv:[UInt8], rand:[UInt8]) -> [UInt8] {
        let y   = self.dm(DiversifierHidingKey, r:rand)
        let div = y ^ ediv
        return ediv
    }
    
    // Version 4.2 [Vol 3, Part H] page 595
    // 2.2.1 Security function e
    // encryptedData = e(key, plaintextData)
    // The most significant octet of key corresponds to key[0]
    func e(key:[UInt8], plainText:[UInt8]) -> [UInt8] {
        let encrypted = Cipher.AES128EncryptWithKey( NSData(bytes:key, length:key.count), plainText: NSData(bytes: plainText, length: plainText.count))
        var bytes = [UInt8](count: encrypted.length, repeatedValue: 0)
        encrypted.getBytes(&bytes, length: bytes.count)
        return bytes
    }

    func decrypt(key:[UInt8], encryptedText:[UInt8]) -> [UInt8] {
        let e = NSData(bytes: encryptedText, length: encryptedText.count)
        let decoded = Cipher.AES128DecryptWithKey( NSData(bytes:key, length:key.count),
//            encryptedText: NSData(bytes: encryptedText, length: encryptedText.count))
            encryptedText: e)
        var bytes = [UInt8](count: decoded.length, repeatedValue: 0)
        decoded.getBytes(&bytes, length: bytes.count)
        return bytes
    }
    
    // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 595
    // 2.2.2 Random Address Hash function ah
    
    // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 596
    // 2.2.3 Confirm value generation function c1 for LE Legacy Pairing
    func c1(
        k:[UInt8],    // 128-bit
        r:[UInt8],    // 128-bit
        preq:[UInt8], // 56-bit
        pres:[UInt8], // 56-bit
        iat:UInt8,    // 1-bit
        rat:UInt8,    // 1-bit
        ia:[UInt8],   // 48-bit
        ra:[UInt8]    // 48-bit
        ) -> [UInt8] {
            
//            println("c1(k:\(k) r:\(r) preq:\(preq) pres:\(pres) iat:\(iat) rat:\(rat) ia:\(ia) ra:\(ra))")
            
            let p1 = pres || preq || [rat] || [iat]
            let p2 = [UInt8](count:(32 / 8), repeatedValue:0) || ia || ra
            return self.e(k, plainText:self.e(k, plainText: r ^ p1) ^ p2)
    }

    func d1(
        k:[UInt8], // 128-bit
        d:[UInt8], // 16-bit
        r:[UInt8]) // 16-bit
        -> [UInt8] {
            let ddash = [UInt8](count:12, repeatedValue:0) || d || r
            return self.e(k, plainText:ddash)
    }
    
    // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 654
    // A.1.1 DIV Mask generation function dm
    // dm(k, r) = e(k, r’) mod 2^16
    func dm(
        k:[UInt8], // 128-bit
        r:[UInt8]) // 64-bit
        -> [UInt8] {
            let rdash = [UInt8](count:8, repeatedValue:0) || r
            let e = self.e(k, plainText:rdash)
            return [UInt8](e[14...15])
    }
    
    // test vector
    // k is 0x00000000000000000000000000000000
    // r is 0x5783D52156AD6F0E6388274EC6702EE0
    // p1 is 0x05000800000302070710000001010001
    // p2 is 0x00000000A1A2A3A4A5A6B1B2B3B4B5B6
    // c1 function is 0x1e1e3fef878988ead2a74dc5bef13b86
    func test_c1() {
        let k           = [UInt8](count: ( 128 / 8), repeatedValue:0)
        let r:[UInt8]   = [0x57, 0x83, 0xD5, 0x21, 0x56, 0xAD, 0x6F, 0x0E, 0x63, 0x88, 0x27, 0x4E, 0xC6, 0x70, 0x2E, 0xE0]
        let p1:[UInt8]  = [0x05, 0x00, 0x08, 0x00, 0x00, 0x03, 0x02, 0x07, 0x07, 0x10, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01]
        let p2:[UInt8]  = [0x00, 0x00, 0x00, 0x00, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6]
        let exp:[UInt8] = [0x1e, 0x1e, 0x3f, 0xef, 0x87, 0x89, 0x88, 0xea, 0xd2, 0xa7, 0x4d, 0xc5, 0xbe, 0xf1, 0x3b, 0x86]
        
        let rp1 = r ^ p1
        let val1  = self.e(k, plainText: rp1)
        let test1 = self.e(k, plainText:val1 ^ p2)
        assert(test1 == exp, "test_c1(), test1")
        
//        let p1 = [0x05, 0x00, 0x08, 0x00, 0x00, 0x03, 0x02, 0x07, 0x07, 0x10, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01]
        let pres:[UInt8] = [0x05, 0x00, 0x08, 0x00, 0x00, 0x03, 0x02 ]
        let preq:[UInt8] = [0x07, 0x07, 0x10, 0x00, 0x00, 0x01, 0x01 ]
        let rat:UInt8 = 0x00
        let iat:UInt8 = 0x01
        
//        let p2 = [0x00, 0x00, 0x00, 0x00,
        let ia:[UInt8] = [0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6]
        let ra:[UInt8] = [0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6]
        
        let test2 = self.c1(k, r: r, preq: preq, pres: pres, iat: iat, rat: rat, ia: ia, ra: ra)
        assert(test2 == exp, "test_c1(), test2")
    }
    
    // BLUETOOTH SPECIFICATION Version 4.2 [Vol 3, Part H] page 598
    // 2.2.4 Key generation function s1 for LE Legacy Pairing
    func s1(
        k:[UInt8], // 128-bit
        r1:[UInt8],
        r2:[UInt8]) -> [UInt8] {
            let r = [UInt8](r1[8...15]) || [UInt8](r2[8...15])
            return self.e(k, plainText: r)
    }

    // test vector
    // k is 0x00000000000000000000000000000000
    // r1' 0x1122334455667788
    // r2' 0x99AABBCCDDEEFF00
    // s1 function, 0x9a1fe1f0e8b0f49b5b4216ae796da062.
    func test_s1() {
        let k           = [UInt8](count: ( 128 / 8), repeatedValue:0)
        let r1d:[UInt8] = [0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88]
        let r2d:[UInt8] = [0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00]
        let exp:[UInt8] = [0x9a, 0x1f, 0xe1, 0xf0, 0xe8, 0xb0, 0xf4, 0x9b, 0x5b, 0x42, 0x16, 0xae, 0x79, 0x6d, 0xa0, 0x62]
        
        let r = r1d || r2d
        let test1 = self.e(k, plainText: r)
        assert(test1 == exp, "test_s1(), test1")
        
        let r1:[UInt8] = [UInt8](count: 8, repeatedValue:0) + r1d
        let r2:[UInt8] = [UInt8](count: 8, repeatedValue:0) + r2d
        
        let test2 = self.s1(k, r1: r1, r2: r2)
        assert(test2 == exp, "test_s1(), test2")
    }
}