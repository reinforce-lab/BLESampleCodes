//
//  libUSBWrapper.h
//  testusb
//
//  Created by AkihiroUehara on 2015/04/01.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libUSB.h"

@interface libUSBWrapper : NSObject

@property (nonatomic, retain, readonly) NSString *productName;

-(id)init;
-(NSData *)readHCIEvent;
-(NSData *)readHCIEventTO;
-(NSData *)executeCommand:(NSData *)data;

-(NSData *)readACLData;
-(BOOL)writeACLData:(NSData *)data;

/*
-(NSString *)scanDevices;

-(BOOL)open:(uint16_t)vendierID productID:(uint16_t)productID;
-(void)close;

-(void)sendCommand:(NSArray *)array completed:(void (^)(enum libusb_error errorCode))completedHandler;
-(void)receiveEvent:(void (^)(NSArray *array, enum libusb_error errorCode))callback;
-(void)sendData:(NSArray *)array completed:(void (^)(enum libusb_error errorCode))completedHandler;
-(void)reeiveData:(void (^)(NSArray *data, enum libusb_error errorCode))callback;
*/
@end
