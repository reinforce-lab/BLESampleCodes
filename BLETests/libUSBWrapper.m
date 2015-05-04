//
//  libUSBWrapper.m
//  testusb
//
//  Created by AkihiroUehara on 2015/04/01.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

#import "libUSBWrapper.h"
#import "libusb.h"

// Interface Number - Alternate Setting - Suggested Endpoint Address - Endpoint Type
// HCI Commands 0   0   0x00    Contrl          8/16/32/64
// HCI Events   0   0   0x81    Interrupt (IN)  16

// USB Dongle
// Class code is 0xE0 - Wireless Controller
// SubClass code is 0x01 - RF Controller
// Protocol code is 0x01 - Bluetooth programming

#define kTimeOut 0

@interface libUSBWrapper () {
    libusb_device_handle *_deviceHandle;
}
@end

@implementation libUSBWrapper
#pragma mark - Properties
#pragma mark - Constructor
-(id)init {
    self = [super init];
    if(self) {
        //        _queue = dispatch_queue_create("com.reinforce-lab.hci", NULL);
        // libusbは、例えば、いくつかのライブラリがそれぞれlibUSBを使用している場合でも、
        // 干渉せずlibUSBを利用できるように、コンテクストを提供しています。
        // デフォルトのコンテクストを使うので、NULLを使います。
        int result = libusb_init(NULL);
        if(result != LIBUSB_SUCCESS) {
            NSLog(@"Fatal error in libusb_init() with an error code: 0x%02x.", result);
            return nil;
        }
        // デバッグレベルを設定
        libusb_set_debug(NULL, LIBUSB_LOG_LEVEL_WARNING);

        BOOL res = [self open:0xa12 productID:0x01];
        if( ! res ) {
            NSLog(@"failed opening a usb device.");
            return nil;
        }
    }
    return self;
}

-(void)dealloc {
    [self close];
    libusb_exit(NULL);
}

#pragma mark -

-(NSData *)readHCIEvent {
    uint8_t buffer[64];
    int actualSize = 0;
    
    libusb_interrupt_transfer(_deviceHandle, LIBUSB_ENDPOINT_IN | 0x01, buffer, sizeof(buffer), &actualSize, 0);
    return [NSData dataWithBytes:buffer length:actualSize];
}

-(NSData *)readHCIEventTO {
    uint8_t buffer[64];
    int actualSize = 0;
    
    libusb_interrupt_transfer(_deviceHandle, LIBUSB_ENDPOINT_IN | 0x01, buffer, sizeof(buffer), &actualSize, 10);
    return [NSData dataWithBytes:buffer length:actualSize];
}

-(NSData *)executeCommand:(NSData *)data {
    /*
    enum libusb_error result = libusb_control_transfer(_deviceHandle, LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_CLASS | LIBUSB_RECIPIENT_INTERFACE,
                                                       0, 0, 0,
                                                       (unsigned char *)data.bytes, data.length, 0);
     */
    libusb_control_transfer(_deviceHandle, LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_CLASS | LIBUSB_RECIPIENT_INTERFACE,
                            0, 0, 0,
                            (unsigned char *)data.bytes, data.length, 0);
    return [self readHCIEvent];
}

-(NSData *)readACLData {
    uint8_t buffer[64];
    int actualSize = 0;
    
    // FIXME タイムアウトを10ミリ秒程度にすると、バスエラーでUSBからデータ読み取りができなくなる。
//    int result = libusb_bulk_transfer(_deviceHandle, LIBUSB_ENDPOINT_IN | 0x02, buffer, sizeof(buffer), &actualSize, 0);
    libusb_bulk_transfer(_deviceHandle, LIBUSB_ENDPOINT_IN | 0x02, buffer, sizeof(buffer), &actualSize, 0);
    return [NSData dataWithBytes:buffer length:actualSize];
}

-(BOOL)writeACLData:(NSData *)data {
    int actualSize = 0;
//    enum libusb_error result = libusb_bulk_transfer(_deviceHandle, LIBUSB_ENDPOINT_OUT | 0x02, (unsigned char *) data.bytes, (int) data.length, &actualSize, 0);
    libusb_bulk_transfer(_deviceHandle, LIBUSB_ENDPOINT_OUT | 0x02, (unsigned char *) data.bytes, (int) data.length, &actualSize, 0);
    return (actualSize == data.length);
}

#pragma mark - Public  methods
-(BOOL)open:(uint16_t)venderID productID:(uint16_t)productID {
    int result;
    
    [self close];
    
    _deviceHandle = libusb_open_device_with_vid_pid(NULL,venderID, productID);
    if(_deviceHandle == NULL) {
        NSLog(@"Can not open a usb device with vender_id:%04x productID:%04x",venderID, productID);
        return false;
    }
    
    result = libusb_set_configuration(_deviceHandle, 1);
    if(result != LIBUSB_SUCCESS) {
        [self close];
        return false;
    }
    
    result = libusb_claim_interface(_deviceHandle, 0);
    if(result != LIBUSB_SUCCESS) {
        [self close];
        return false;
    }
    
    return true;
}

-(void)close {
    if(_deviceHandle != NULL) {
        libusb_close(_deviceHandle);
        _deviceHandle = NULL;
    }
}

-(void)sendCommand:(NSData *)data completed:(void (^)(enum libusb_error result))completedHandler {
    enum libusb_error result = libusb_control_transfer(_deviceHandle, LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_CLASS | LIBUSB_RECIPIENT_INTERFACE,
                                                       0, 0, 0,
                                                       (unsigned char *)data.bytes, data.length, kTimeOut);
    
    if(completedHandler != nil) {
        if(result >= 0) {
            result = LIBUSB_SUCCESS;
        }
        completedHandler(result);
    }
}

-(void)receiveEvent:(void (^)(NSData *data, enum libusb_error errorCode))callback {
    uint8_t buffer[64];
    
    int actualSize;
    int result = libusb_interrupt_transfer(_deviceHandle, LIBUSB_ENDPOINT_IN | 0x01, buffer, sizeof(buffer), &actualSize, kTimeOut);
    if(callback != nil) {
        NSData *returnData = [NSData dataWithBytes:buffer length:actualSize];
        callback(returnData, result);
    }
}

-(void)sendData:(NSData *)data completed:(void (^)(enum libusb_error result))completedHandler {
    int actualSize;
    enum libusb_error result = libusb_bulk_transfer(_deviceHandle, LIBUSB_ENDPOINT_OUT | 0x02, (unsigned char *) data.bytes, (int) data.length, &actualSize, kTimeOut);
    if(completedHandler != nil) {
        completedHandler(result);
    }
}

-(void)receiveData:(void (^)(NSData *data, enum libusb_error errorCode))callback {
    uint8_t buffer[64];
    
    int actualSize;
    int result = libusb_bulk_transfer(_deviceHandle, LIBUSB_ENDPOINT_IN | 0x02, buffer, sizeof(buffer), &actualSize, kTimeOut);
    if(callback != nil) {
        NSData *returnData = [NSData dataWithBytes:buffer length:actualSize];
        callback(returnData, result);
    }
}

-(NSString *)scanDevices {
    NSMutableString *logText = [[NSMutableString alloc] init];
    
    libusb_device **devices;
    ssize_t numberOfDevices;
    struct libusb_device_descriptor deviceDescriptor;
    char buffer[256];
    
    numberOfDevices = libusb_get_device_list(NULL, &devices);
    for(int i=0; i < numberOfDevices; i++) {
        libusb_device *device = devices[i];
        int result;
        result = libusb_get_device_descriptor(device, &deviceDescriptor);
        if( result == LIBUSB_SUCCESS) {
            [logText appendString:
             [NSString stringWithFormat:@"VenderID:0x%04x ProductID:0x%04x (bus %d, device %d) - class %x subclass %x protocol %x ",
              deviceDescriptor.idVendor, deviceDescriptor.idProduct,
              libusb_get_bus_number(device), libusb_get_device_address(device),
              deviceDescriptor.bDeviceClass, deviceDescriptor.bDeviceSubClass, deviceDescriptor.bDeviceProtocol]];
            // open device
            libusb_device_handle *deviceHandle = NULL;
            result = libusb_open(device, &deviceHandle);
            if(result == LIBUSB_SUCCESS) {
                // 製造者名を取得
                result = libusb_get_string_descriptor_ascii(deviceHandle, deviceDescriptor.iManufacturer, (unsigned char *) buffer, sizeof(buffer));
                if(result == LIBUSB_SUCCESS) {
                    [logText appendFormat:@"Manufacturer:%@ ", [NSString stringWithUTF8String:buffer]];
                }
                result = libusb_get_string_descriptor_ascii(deviceHandle, deviceDescriptor.iProduct, (unsigned char *) buffer, sizeof(buffer));
                if(result == LIBUSB_SUCCESS) {
                    [logText appendFormat:@"Product:%@ ", [NSString stringWithUTF8String:buffer]];
                }
                libusb_close(deviceHandle);
            }
            [logText appendString:@"\n"];
        }
    }
    libusb_free_device_list(devices, TRUE);
    
    return logText;
}
@end
