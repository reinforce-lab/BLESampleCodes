//
//  NSData+CommonCrypto.h
//  BLETests
//
//  Created by AkihiroUehara on 2015/05/09.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonCryptor.h>

@interface Cipher : NSObject
+ (NSData *)AES128EncryptWithKey:(NSData *)key plainText:(NSData *)plainText;
+ (NSData *)AES128EncryptWithKey:(NSData *)key iv:(NSData *)iv plainText:(NSData *)plainText;
+ (NSData *)AES128DecryptWithKey:(NSData *)key encryptedText:(NSData *)encryptedText;

@end