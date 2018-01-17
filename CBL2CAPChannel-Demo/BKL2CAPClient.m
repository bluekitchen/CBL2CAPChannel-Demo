//
//  BKL2CAPClient.m
//  CBL2CAPChannel-Demo
//
//  Created by Matthias Ringwald on 15.01.18.
//  Copyright © 2018 BlueKitchen GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BKL2CAPClient.h"

@implementation BKL2CAPClient

-(id)init {
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    return self;
}
-(id)initWithNamePrefix:(NSString *)namePrefix andPSM:(CBL2CAPPSM) psm{
    self->psm = psm;
    self->namePrefix = namePrefix;
    return [self init];
}

-(id)initWithUUID:(CBUUID *)uuid andPSM:(CBL2CAPPSM) psm
{
    self->psm = psm;
    self->uuid = uuid;
    return [self init];
}

/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        // In a real app, you'd deal with all the states correctly
        return;
    }
    
    // The state must be CBCentralManagerStatePoweredOn, let's connect
    [self scan];
}

/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
    self->scanning = YES;
    NSArray * uuidList = nil;
    if (self->uuid){
        uuidList = @[self->uuid];
    }
    [self.centralManager scanForPeripheralsWithServices:uuidList
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
    NSLog(@"Scanning started");
}


/** This callback comes whenever a peripheral that is advertising the GRIP_AND_SHOOT_SERVICE_UUID is discovered.
 *  RSSI could be checked
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered %@ at %@ dBm, adv %@", peripheral.name, RSSI, advertisementData);
    
    // verify name
    if (self->namePrefix && ![peripheral.name hasPrefix:self->namePrefix]) return;
    
    // Ok, it's in range - have we already seen it?
    if (self.discoveredPeripheral != peripheral) {
        
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        
        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    [self cleanup];
    
    [self.delegate disconnected];

    NSLog(@"Device disconnected%@. (%@)", peripheral, [error localizedDescription]);
    self.discoveredPeripheral = nil;
    
    // let's start scanning again
    [self scan];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    // Stop scanning
    if (self->scanning){
        self->scanning = NO;
        [self.centralManager stopScan];
        NSLog(@"Scanning stopped");
    }
    
    // Make sure we get the discovery callbacks
    self.discoveredPeripheral.delegate = self;
    
    // connected, try to open l2cap channel
    [self.discoveredPeripheral openL2CAPChannel:self->psm];
}

-(void)peripheral:(CBPeripheral *)peripheral didOpenL2CAPChannel:(CBL2CAPChannel *)channel error:(NSError *)error
{
    if(error){
        NSLog(@"%@", error);
    }
    
    self->l2capChannel = channel;
    
    self.outputStream = self->l2capChannel.outputStream;
    self.inputStream  = self->l2capChannel.inputStream;
    
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                            forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
    
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                           forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    
    // notify delegate
    [self.delegate connected];
}

/** Call this when things either go wrong, or you're done with the connection.
 *  This cancels any subscriptions if there are any, or straight disconnects if not.
 *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
 */
- (void)cleanup
{
    if (self.inputStream) {
        NSLog(@"Close input stream");
        [self.inputStream close];
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                    forMode:NSDefaultRunLoopMode];
        self.inputStream = nil;
    }
    if (self.outputStream) {
        NSLog(@"Close output stream");
        [self.outputStream close];
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                     forMode:NSDefaultRunLoopMode];
        self.outputStream = nil;
    }
    
    // Don't do anything if we're not connected
    if (self.discoveredPeripheral.state != CBPeripheralStateConnected) {
        return;
    }
    


    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}

@end

