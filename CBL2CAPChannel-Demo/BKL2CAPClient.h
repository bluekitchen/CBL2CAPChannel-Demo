//
//  BKL2CAPClient.h
//  CBL2CAPChannel-Demo
//
//  Created by Matthias Ringwald on 15.01.18.
//  Copyright © 2018 BlueKitchen GmbH. All rights reserved.
//

#ifndef BKL2CAPClient_h
#define BKL2CAPClient_h

#import <CoreBluetooth/CoreBluetooth.h>

@protocol BKL2CAPClientDelegate
-(void) connected;
-(void) disconnected;
@end

@interface BKL2CAPClient : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>
{
    BOOL scanning;
    NSString *namePrefix;
    CBUUID   *uuid;
    CBL2CAPPSM psm;
    CBL2CAPChannel * l2capChannel;
}
-(id)initWithNamePrefix:(NSString *)namePrefix andPSM:(CBL2CAPPSM) psm;
-(id)initWithUUID:(CBUUID *)uuid andPSM:(CBL2CAPPSM) psm;

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
@property (strong, nonatomic) id<BKL2CAPClientDelegate> delegate;
@property (strong, nonatomic) NSOutputStream* outputStream;
@property (strong, nonatomic) NSInputStream* inputStream;
@end

#endif /* BKL2CAPClient_h */
