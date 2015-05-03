//
//  USBDeviceManager.h
//  testusb
//
//  Created by AkihiroUehara on 2015/04/09.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BluetoothUSBAdaptor : NSObject
@property (nonatomic, retain, readonly) NSString *productName;

-(id)init;
-(NSData *)readHCIEvent;
-(NSData *)readHCIEventTO;
-(NSData *)executeCommand:(NSData *)data;

-(NSData *)readACLData;
-(BOOL)writeACLData:(NSData *)data;
@end
