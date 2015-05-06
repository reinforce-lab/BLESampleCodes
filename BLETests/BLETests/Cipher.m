//
//  NSData+CommonCrypto.m
//  BLETests
//
//  Created by AkihiroUehara on 2015/05/09.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

#import "Cipher.h"

@implementation Cipher

+ (NSData *)AES128EncryptWithKey:(NSData *)key plainText:(NSData *)plainText
{
    return [Cipher AES128EncryptWithKey:key iv:nil plainText:plainText];
}

+ (NSData *)AES128EncryptWithKey:(NSData *)key iv:(NSData *)iv plainText:(NSData *)plainText
{
    size_t numBytesEncrypted = 0;
    void *buffer = malloc( plainText.length + kCCBlockSizeAES128 );

    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          0x00, //No padding, Cipher Block Chaining (CBC) mode
                                          key.bytes,
                                          kCCKeySizeAES128,
                                          iv == nil ? nil : iv.bytes,
                                          plainText.bytes,
                                          plainText.length,
                                          buffer,
                                          plainText.length + kCCBlockSizeAES128,
                                          &numBytesEncrypted);

    NSData *data = nil;
    if(cryptStatus == kCCSuccess) {
        data = [NSData dataWithBytes:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return data;
}

+ (NSData *)AES128DecryptWithKey:(NSData *)key encryptedText:(NSData *)encryptedText {
    size_t numBytesDecrypted = 0;
    void *buffer = malloc( encryptedText.length + kCCBlockSizeAES128 );
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          0x00, //No padding, Cipher Block Chaining (CBC) mode
                                          key.bytes,
                                          kCCKeySizeAES128,
                                          nil,
                                          encryptedText.bytes,
                                          encryptedText.length,
                                          buffer,
                                          encryptedText.length + kCCBlockSizeAES128,
                                          &numBytesDecrypted);
    
    NSData *data = nil;
    if(cryptStatus == kCCSuccess) {
        data = [NSData dataWithBytes:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return data;
}

@end
