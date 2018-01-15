//
//  ViewController.m
//  CBL2CAPChannel-Demo
//
//  Created by Matthias Ringwald on 15.01.18.
//  Copyright © 2018 BlueKitchen GmbH. All rights reserved.
//

#import "ViewController.h"

#define TEST_PACKET_SIZE 1000

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    // instantiate and start scanning
    self.l2capClient = [[BKL2CAPClient new] initWithNamePrefix:@"LE Data Channel" andPSM:0x25];
    self.l2capClient.delegate = self;
    
    // update ui
    [self disconnected];
}

- (void)connected {
    self.statusLabel.text = @"Connected. start streaming";

    self->outputStream = self.l2capClient.outputStream;
    self->inputStream  = self.l2capClient.inputStream;
    
    self->outputStream.delegate = self;
    self->inputStream.delegate = self;

    // reset track data
    [self trackReset];
}

- (void)disconnected {
    self.statusLabel.text = @"Scanning for device";
}

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    uint8_t buf[1024];
    NSData * data;
    NSInteger len;
    NSError *theError;
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            NSLog(@"NSStreamEventOpenCompleted");
            break;
        case NSStreamEventHasSpaceAvailable:
            [self sendStreamData];
            break;
        case NSStreamEventHasBytesAvailable:
            len = [(NSInputStream *)aStream read:buf maxLength:1024];
            NSLog(@"NSStreamEventHasBytesAvailable (this %@), read %u bytes",aStream, (int) len);
            if(len) {
                [NSData dataWithBytes:buf length:len];
                NSLog(@"%@", data);
            }
            break;
        case NSStreamEventErrorOccurred:
            theError = [aStream streamError];
            NSLog(@"NSStreamEventErrorOccurred: %@", theError);
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            break;
        case NSStreamEventNone:
            break;
        default:
            NSLog(@"Other %02x", (int) eventCode);
            break;
    }
}

static uint32_t total_bytes = 0;

-(void)trackReset{
    total_bytes = 0;
}

-(void)trackData:(int)numBytes{
    // track bytes and update status label periodically
    total_bytes += numBytes;
    NSLog(@"Sent %u", total_bytes);
    self.statusLabel.text = [NSString stringWithFormat:@"Sent: %u bytes", total_bytes];
}

-(void)sendStreamData
{
    // check
    if (![self->outputStream hasSpaceAvailable]){
        NSLog(@"No space available, skip");
        return;
    }
    
    // prepare 1kB data block
    static int counter = 'a';
    uint8_t test_data[TEST_PACKET_SIZE];
    memset(test_data, counter++, TEST_PACKET_SIZE);
    if (counter > 'z') counter = 'a';
    
    NSData* data = [NSData dataWithBytes:test_data length:TEST_PACKET_SIZE];
    NSInteger res = [self->outputStream write:[data bytes] maxLength:[data length]];
    if (res != TEST_PACKET_SIZE){
        NSLog(@"Write %u bytes, res %d", TEST_PACKET_SIZE, (int) res);
    }
    
    // track
    [self trackData:(int)[data length]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
