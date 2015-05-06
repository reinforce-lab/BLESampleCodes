//
//  USBDeviceManager.m
//  testusb
//
//  Created by AkihiroUehara on 2015/04/09.
//  Copyright (c) 2015年 AkihiroUehara. All rights reserved.
//

#import "BluetoothUSBAdaptor.h"
#include <mach/mach.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/usb/USBSpec.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/usb/IOUSBUserClient.h>

// Bluetooth Spec. ver4.2 [Vol4, Part B] page 22
// Table 2.1: USB Primary firmware interface and endpoints
// Interface number, Alternate setting, Suggested endpoint address, Endpoint type, Suggested max packet size, USB polling interval
// HCI Commmands
// N/A  N/A 0x00    Control         8/16/32/64  NA
// HCI Events
// 0    0   0x81    Interrupt(IN)   16          variable
// ACL Data
// 0    0   0x82    Bulk(IN         32/64       variable
// 0    0   0x02    Bulk(Out)       32/64       variable

// 3.1 BLUETOOTH CODES
// Code     Label           Value   Description
// Class    bDeviceClass    0xE0    Wireless Controller
// Subclass bDeviceSubClass 0x01    RF Controller
// Protocol bDeviceProtocol 0x01    Bluetooth Primary Controller

@interface BluetoothUSBAdaptor() {
    mach_port_t _masterPort;
    io_service_t _handle;
    IOCFPlugInInterface**        _pluginInterface;
    IOUSBDeviceInterface500**    _deviceInterface;
    IOUSBInterfaceInterface550** _interfaceInterface;
    NSDictionary*                _endPointsToPipe;
}
@end

@implementation BluetoothUSBAdaptor
#pragma mark - Properties
#pragma mark - Constructor
// Bluetooth USBドングルと接続できなければ、nilを返します。
-(id)init {
    self = [super init];
    if(self != nil) {
        _masterPort = [self createMasterPort];
        _handle = [self findDeviceHandler:_masterPort];
        _pluginInterface = [self createPluginInterface:_handle];
        _deviceInterface = [self createDeviceInterface:_pluginInterface];
        [self openDeviceInterface:_deviceInterface];
        [self configureDevice:_deviceInterface];
        _interfaceInterface = [self findFirstInterface:_deviceInterface];
        [self openInterfaceInterface:_interfaceInterface];
        _endPointsToPipe = [self getEndPointsToPipe];
//NSLog(@"endpoints: %@", _endPointsToPipe);
        
    }
    /*
     if(_deviceInterface == NULL || _interfaceInterface == NULL) {
     [self disposeInterfaces];
     }*/
    return self;
}

-(void)dealloc {
    [self disposeInterfaces];
}

#pragma mark - Private methods
-(void)disposeInterfaces {
    [self closeInterfaceInterface:_interfaceInterface];
    [self disposeInterfaceInterface:_interfaceInterface];
    [self closeDeviceInterface:_deviceInterface];
    [self disposeDeviceInterface:_deviceInterface];
    [self disposePluginInterface:_pluginInterface];
    [self disposeDeviceHandler:_handle];
    [self disposeMasterPort:_masterPort];
    
    _interfaceInterface = NULL;
    _deviceInterface = NULL;
    _pluginInterface = NULL;
    _handle     = 0;
    _masterPort = 0;
}

//Create a master port for communication with the I/O Kit.
-(mach_port_t)createMasterPort {
    mach_port_t masterPort;
    kern_return_t result = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if(result != KERN_SUCCESS || masterPort == 0) {
        NSLog(@"Fatal error in IOMasterPort(), error code %08x, port:%x", result, masterPort);
        return 0;
    }
    return masterPort;
}

-(void)disposeMasterPort:(mach_port_t) port {
    mach_port_deallocate(mach_task_self(), port);
}

-(io_object_t)findDeviceHandler:(mach_port_t)port {
    kern_return_t result;
    
    CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    if(matchingDict == nil) {
        NSLog(@"Could not create a USB matching dictionary.");
        return 0;
    }
    
    uint8_t val;
    val = 0xE0;
    CFDictionarySetValue(matchingDict, CFSTR(kUSBDeviceClass), CFNumberCreate(kCFAllocatorDefault, kCFNumberCharType, &val));
    val = 0x01;
    CFDictionarySetValue(matchingDict, CFSTR(kUSBDeviceSubClass), CFNumberCreate(kCFAllocatorDefault, kCFNumberCharType, &val));
    val = 0x01;
    CFDictionarySetValue(matchingDict, CFSTR(kUSBDeviceProtocol), CFNumberCreate(kCFAllocatorDefault, kCFNumberCharType, &val));
    
    io_iterator_t io_iterator = 0;
    result = IOServiceGetMatchingServices(port, matchingDict, &io_iterator);
    if(result != KERN_SUCCESS) {
        NSLog(@"Error in IOServiceGetMatchingServices(), error_code:%08x", result);
        return 0;
    }
    
    io_object_t device = IO_OBJECT_NULL;
    while(true) {
        device = IOIteratorNext(io_iterator);
        if(device == IO_OBJECT_NULL) {
            break;
        }
        // Read its properties.
        CFMutableDictionaryRef properties = nil;
        result = IORegistryEntryCreateCFProperties(device,  &properties, kCFAllocatorDefault, 0);
        if(result != KERN_SUCCESS) {
            NSLog(@"Unable to get properties, error_code:%08x", result);
            CFRelease(properties);
            IOObjectRelease(device);
            continue;
        }
        // Confirm that its Vendor ID is not that of Apple.
        CFNumberRef vendorID = (CFNumberRef)CFDictionaryGetValue(properties, (__bridge const void *)(@(kUSBVendorID)));
        if(vendorID == nil) {
            NSLog(@"Unable to get vendorID");
            CFRelease(properties);
            IOObjectRelease(device);
            continue;
        }
        
        int vid = 0;
        CFNumberGetValue(vendorID, kCFNumberIntType, &vid);
        if(vid == kAppleVendorID) {
            // apples's usb bluetooth dongle.
            CFRelease(properties);
            IOObjectRelease(device);
            continue;
        }
        
        // read product name
        NSString *productString = CFDictionaryGetValue(properties, (__bridge const void *)(@(kUSBProductString)));
        if( productString != nil) {
            _productName = [NSString stringWithString:productString];
        } else {
            _productName = @"unknown product name";
        }
        
        uint16 deviceReleaseNumber = 0;
        NSNumber *devnum = CFDictionaryGetValue(properties, (__bridge const void *)(@(kUSBDeviceReleaseNumber)));
        if( devnum != nil ) {
            deviceReleaseNumber = [devnum unsignedIntegerValue];
        }

        NSLog(@"Device found, vendorID:0x%04x DeviceReleaseNumber:0x%04x product name:%@", vid, deviceReleaseNumber, _productName);
        CFRelease(properties);
        break;
    }
    IOObjectRelease(io_iterator);
    
    return device;
}

-(void)disposeDeviceHandler:(io_object_t)device {
    if(device == IO_OBJECT_NULL) {
        return;
    }
    IOObjectRelease(device);
}

-(IOCFPlugInInterface **)createPluginInterface:(io_object_t)device {
    if(device == IO_OBJECT_NULL) {
        return NULL;
    }
    
    IOCFPlugInInterface **pluginInterface = NULL;
    SInt32 score = 0;
    HRESULT result = IOCreatePlugInInterfaceForService(device, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &pluginInterface, &score);
    if(result != SEVERITY_SUCCESS || pluginInterface == NULL) {
        NSLog(@"Failure in IOCreatePluginInterfaceForService(), error_code:%08x", result);
        [self disposePluginInterface:pluginInterface];
        return NULL;
    }
    return pluginInterface;
}

-(void)disposePluginInterface:(IOCFPlugInInterface **)pluginInterface {
    if(pluginInterface != NULL) {
        (*pluginInterface)->Release(pluginInterface);
    }
}

-(IOUSBDeviceInterface500 **)createDeviceInterface:(IOCFPlugInInterface **)pluginInterface {
    if(pluginInterface == NULL) {
        return NULL;
    }
    IOUSBDeviceInterface500 **interface = NULL;
    HRESULT result = (*pluginInterface)->QueryInterface(pluginInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID500),(LPVOID *)&interface);
    if(result != SEVERITY_SUCCESS || interface == NULL) {
        NSLog(@"%s, Failure in QueryInterface(), error_code:%08x", __PRETTY_FUNCTION__, result);
        return NULL;
    }
    return interface;
}

-(void)disposeDeviceInterface:(IOUSBDeviceInterface500 **)deviceInterface {
    if(deviceInterface != NULL) {
        (*deviceInterface)->Release(deviceInterface);
    }
}

-(BOOL)configureDevice:(IOUSBDeviceInterface500 **)deviceInterface {
    IOReturn result;
    
    UInt8 numConfig = 0;
    result = (*deviceInterface)->GetNumberOfConfigurations(deviceInterface, &numConfig);
    if(result != kIOReturnSuccess || numConfig == 0) {
        NSLog(@"Failure in GetNumberOfConfigurations(), result:%x", result);
        return NO;
    }
    
    IOUSBConfigurationDescriptorPtr configDesc = NULL;
    result = (*deviceInterface)->GetConfigurationDescriptorPtr(deviceInterface, 0, &configDesc);
    if(result != kIOReturnSuccess || configDesc == NULL) {
        NSLog(@"Failure in GetConfigurationDescriptorPtr(), result:%x", result);
        return NO;
    }
    result = (*deviceInterface)->SetConfiguration(deviceInterface, configDesc->bConfigurationValue);
    if(result != kIOReturnSuccess ) {
        NSLog(@"Failure in SetConfiguration(), result:%x", result);
        return NO;
    }
    
    return YES;
}

-(IOUSBInterfaceInterface550 **)findFirstInterface:(IOUSBDeviceInterface500 **)deviceInterface {
    if(deviceInterface == NULL) {
        return NULL;
    }
    
    IOUSBInterfaceInterface550 **interfaceInterface = NULL;
    
    IOUSBFindInterfaceRequest request;
    request.bInterfaceClass    = kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting  = kIOUSBFindInterfaceDontCare;
    io_iterator_t iterator = IO_OBJECT_NULL;
    io_service_t interface = IO_OBJECT_NULL;
    
    IOReturn ioResult = (*deviceInterface)->CreateInterfaceIterator(deviceInterface, &request, &iterator);
    if(ioResult != kIOReturnSuccess) {
        NSLog(@"%s, Error in CreateInterfaceIterator(), error code:%x", __PRETTY_FUNCTION__, ioResult);
        IOObjectRelease(iterator);
        return nil;
    }
    
    IOCFPlugInInterface ** pluginInterface = NULL;
    SInt32 score = 0;
    while((interface = IOIteratorNext(iterator))) {
        kern_return_t kret = IOCreatePlugInInterfaceForService(interface, kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID, &pluginInterface, &score);
        IOObjectRelease(interface);
        if(kret != 0 || pluginInterface == NULL ) {
            continue;
        }
        
        HRESULT res = (*pluginInterface)->QueryInterface(pluginInterface, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID550),(LPVOID)&interfaceInterface);
        IODestroyPlugInInterface(pluginInterface);
        if(res != kIOReturnSuccess) {
            continue;
        }
        
        break;
    }
    
    IOObjectRelease(iterator);
    return interfaceInterface;
}

-(void)disposeInterfaceInterface:(IOUSBInterfaceInterface550 **)interfaceInterface {
    if(interfaceInterface == NULL) {
        return;
    }
    (*interfaceInterface)->Release(interfaceInterface);
}

-(BOOL)openInterfaceInterface:(IOUSBInterfaceInterface550 **)interfaceInterface {
    if(interfaceInterface == NULL) {
        return NO;
    }
    IOReturn result = (*interfaceInterface)->USBInterfaceOpen(interfaceInterface);
    return (result == kIOReturnSuccess);
}

-(BOOL)closeInterfaceInterface:(IOUSBInterfaceInterface550 **)interfaceInterface {
    if(interfaceInterface == NULL) {
        return NO;
    }
    IOReturn result = (*interfaceInterface)->USBInterfaceClose(interfaceInterface);
    return (result == kIOReturnSuccess);
}

-(BOOL)openDeviceInterface:(IOUSBDeviceInterface500 **)deviceInterface {
    if(deviceInterface == NULL) {
        return NO;
    }
    IOReturn result = (*deviceInterface)->USBDeviceOpen(deviceInterface);
    if(result != kIOReturnSuccess) {
        NSLog(@"Failure in USBDeviceOpen(), error_code:%08x", result);
        return NO;
    }
    return YES;
}

-(BOOL)closeDeviceInterface:(IOUSBDeviceInterface500 **)deviceInterface {
    if(deviceInterface == NULL) {
        return NO;
    }
    IOReturn result = (*deviceInterface)->USBDeviceClose(deviceInterface);
    if(result != kIOReturnSuccess) {
        NSLog(@"Failure in USBDeviceClose(), error_code:%08x", result);
        return NO;
    }
    return YES;
}

// デバイスをリセットします。デバイスはOpenされていなければなりません。
-(BOOL)resetDeviceInterface:(IOUSBDeviceInterface500 **)deviceInterface {
    if(deviceInterface == NULL) {
        return NO;
    }
    IOReturn result = (*deviceInterface)->ResetDevice(deviceInterface);
    if(result != kIOReturnSuccess) {
        NSLog(@"Failure in ResetDevice(), error_code:%08x", result);
        return NO;
    }
    return YES;
}

-(NSDictionary *)getEndPointsToPipe {
    if(_interfaceInterface == nil) {
        return nil;
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    UInt8 numOfEndpoints = 0;
    IOReturn result = (*_interfaceInterface)->GetNumEndpoints(_interfaceInterface, &numOfEndpoints);
    if(result != kIOReturnSuccess) {
        NSLog(@"Error in GetNumEndpoints(), error_code:%x", result);
        return dict;
    }
    
    UInt8 direction = 0;
    UInt8 number = 0;
    UInt8 transferType = 0;
    UInt8 interval = 0;
    UInt16 maxPacketSize = 0;
    for(int i=1; i <= numOfEndpoints; i++ ) {
        result = (*_interfaceInterface)->GetPipeProperties(_interfaceInterface, i, &direction, &number,&transferType, &maxPacketSize, &interval);
        if(result != kIOReturnSuccess) {
            NSLog(@"Error in GetPipeProperties(), error_code:%x", result);
            return dict;
        }
//NSLog(@"interface:%d direction:%d, number:%d, transferType:0x%x, maxpacketSize:%d, interval:%d", i, direction, number, transferType, maxPacketSize, interval);
        // Endpointの最上位ビットはdirectionを表す
        UInt8 endpoint = (direction << 7) | number;
        dict[@(endpoint)] = @(i); // Endpoint-pipe の対応
    }
    return dict;
}

#pragma mark - Public methods
/*
-(BOOL)flush:(UInt8)endpoint {
    if(_interfaceInterface == NULL) {
        return NO;
    }
    NSNumber *pipe = _endPointsToPipe[@(endpoint)];
    if( pipe == nil) {
        return NO;
    }
    
    IOReturn result = (*_interfaceInterface)->ClearPipeStall(_interfaceInterface, [pipe unsignedCharValue]);
    return (result == kIOReturnSuccess);
}*/

// HCIイベントを受信
-(NSData *)readHCIEvent {
    NSNumber *hciEventPipe = _endPointsToPipe[@(0x81)]; // LIBUSB_ENDPOINT_IN (0x80) | 0x01
    UInt8 buf[32];
    UInt32 size = sizeof(buf);
    IOReturn result = (*_interfaceInterface)->ReadPipe(_interfaceInterface, [hciEventPipe unsignedCharValue], buf, &size);
    // 結果をNSDataにして送信
    if(result == kIOReturnSuccess) {
        return [NSData dataWithBytes:buf length:size];
    } else {
        return [NSData dataWithBytes:buf length:0];
    }
}

// HCIイベントを受信
-(NSData *)readHCIEventTO {
    NSNumber *hciEventPipe = _endPointsToPipe[@(0x81)]; // LIBUSB_ENDPOINT_IN (0x80) | 0x01
    UInt8 buf[32];
    UInt32 size = sizeof(buf);
    IOReturn result = (*_interfaceInterface)->ReadPipeTO(_interfaceInterface, [hciEventPipe unsignedCharValue], buf, &size, 10 ,10);
    // 結果をNSDataにして送信
    if(result == kIOReturnSuccess) {
        return [NSData dataWithBytes:buf length:size];
    } else {
        return [NSData dataWithBytes:buf length:0];
    }
}

-(NSData *)executeCommand:(NSData *)data {
    if(_interfaceInterface == NULL) {
        return nil;
    }
    NSNumber *hciEventPipe = _endPointsToPipe[@(0x81)]; // LIBUSB_ENDPOINT_IN (0x80) | 0x01
    if(hciEventPipe == nil) {
        return nil;
    }
    if(data == nil) {
        return nil;
    }
    
    // コマンドを送信
    IOUSBDevRequestTO request;
    // uint8_t bmRequestType,
    // 2.2.2 Primary Controller Function in a Composite Device, Host-to-Interface class request, interface as target
    // LIBUSB_REQUEST_TYPE_CLASS = (0x01 << 5), LIBUSB_RECIPIENT_INTERFACE = 0x01,
    request.bmRequestType = 0x21;
    // uint8_t bRequest, uint16_t wValue, uint16_t wIndex (actual interface number whithin the composite device.),
    request.bRequest = 0;
    request.wValue = 0;
    request.wIndex = 0;
    
    request.pData    = (void *)data.bytes;
    request.wLength  = data.length;
    request.wLenDone = 0;
    request.completionTimeout = 100;
    request.noDataTimeout     = 100;
    
    IOReturn result = (*_interfaceInterface)->ControlRequestTO(_interfaceInterface, 0, &request);
    if(result != kIOReturnSuccess) {
        return nil;
    }
    
    return [self readHCIEvent];
}

-(BOOL)writeACLData:(NSData *)data {
    if(_interfaceInterface == NULL) {
        return NO;
    }
    
    NSNumber *hciACLDataPipe = _endPointsToPipe[@(0x02)]; // LIBUSB_ENDPOINT_OUT (0x00) | 0x02
    if(hciACLDataPipe == nil) {
        return NO;
    }
    if(data == nil || data.length == 0) {
        return YES;
    }
    
    IOReturn result = (*_interfaceInterface)->WritePipe(_interfaceInterface, [hciACLDataPipe unsignedCharValue], (void*)data.bytes, (UInt32)data.length);
    if(result != kIOReturnSuccess) {
        NSLog(@"Fatal errorin writeACLData(), errorCode:0x%04x", result);
    }

    
    return (result == kIOReturnSuccess);
}

-(NSData *)readACLData {
    if(_interfaceInterface == NULL) {
        return NO;
    }
    
    NSNumber *hciACLDataPipe = _endPointsToPipe[@(0x82)]; // LIBUSB_ENDPOINT_IN (0x80) | 0x02
    if(hciACLDataPipe == nil) {
        return NO;
    }
    
    /*
    IOReturn stat = (*_interfaceInterface)->GetPipeStatus(_interfaceInterface, [hciACLDataPipe unsignedIntegerValue]);
    if(stat == kIOUSBPipeStalled) {
        NSLog(@"%s Pipe is stalled.", __PRETTY_FUNCTION__);
        (*_interfaceInterface)->ResetPipe(_interfaceInterface, [hciACLDataPipe unsignedIntegerValue]);
    }
      */
    UInt8 buf[256];
    UInt32 size = sizeof(buf);
    IOReturn result = (*_interfaceInterface)->ReadPipe(_interfaceInterface, [hciACLDataPipe unsignedCharValue], buf, &size);
    if(result == kIOReturnSuccess) {
        return [NSData dataWithBytes:buf length:size];
    } else {
        return [NSData data];
    }
}

@end
