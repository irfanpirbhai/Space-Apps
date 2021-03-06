//
//  DIOSocketManager.m
//  Dioresta
//
//  Created by Brian Gilham on 2014-04-12.
//  Copyright (c) 2014 Space Apps. All rights reserved.
//

#import "DIOSocketManager.h"

#import <socket.IO/SocketIO.h>
#import <socket.io/SocketIOPacket.h>

static NSString *const DIOHost = @"192.168.106.50";
static NSInteger const DIOPort = 8000;
static NSString *const DIONamespace = @"";

@interface DIOSocketManager() <SocketIODelegate>

@property (strong, nonatomic) SocketIO *socket;

@end

@implementation DIOSocketManager

#pragma mark - Shared Manager
+ (id)sharedManager
{
    static DIOSocketManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] initWithHost:DIOHost
                                              port:DIOPort
                                         namespace:DIONamespace];
    });
    return sharedManager;
}

- (id)initWithHost:(NSString *)host
              port:(NSInteger)port
         namespace:(NSString *)namespace
{
    if((self = [super init])) {
        self.socket = [[SocketIO alloc] initWithDelegate:self];
        [self.socket connectToHost:host
                            onPort:port];
    }
    
    return self;
}

#pragma mark - Utilities
- (NSString *)deviceID
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"DIODeviceID"];
}

#pragma mark - Communication
- (void)sendAction:(NSString *)action andData:(NSDictionary *)data
{
    if(![self.socket isConnected]) {
        [self.socket connectToHost:DIOHost
                            onPort:DIOPort];
    }
    
    NSMutableDictionary *actionData = [NSMutableDictionary dictionaryWithDictionary:data];
    
    [actionData addEntriesFromDictionary:@{
                                           @"playerID":[NSString stringWithFormat:@"player%@", [self deviceID]]
                                           }];
    
    [self.socket sendEvent:action withData:actionData];
}

#pragma mark - Socket.IO Delegate
- (void)socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet
{
    NSLog(@"DID RECEIVE EVENT %@", packet);
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData: [packet.data dataUsingEncoding:NSUTF8StringEncoding]
                                                         options: NSJSONReadingMutableContainers
                                                           error: nil];
    if([data[@"name"] isEqualToString:@"commonMineralCollected"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DIOCommonCollected" object:nil userInfo:@{@"name":data[@"args"][0][@"name"], @"amount":data[@"args"][0][@"amount"], @"element":data[@"args"][0][@"element"]}];
    } else if([data[@"name"] isEqualToString:@"scarceMineralCollected"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DIOScarceCollected" object:nil userInfo:@{@"name":data[@"args"][0][@"name"], @"amount":data[@"args"][0][@"amount"], @"element":data[@"args"][0][@"element"]}];
    }
    
    NSLog(@"data: %@", data);
}

- (void)socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet
{
    NSLog(@"DID RECEIVE JSON %@", packet);
}

- (void)socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet
{
    NSLog(@"DID RECEIVE MESSAGE %@", packet);
}

- (void)socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet
{
    NSLog(@"DID SEND MESSAGE %@", packet);
}

- (void)socketIO:(SocketIO *)socket onError:(NSError *)error
{
    NSLog(@"ON ERROR %@", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DIODidDisconnectWithError" object:nil];
    [self.socket connectToHost:DIOHost
                        onPort:DIOPort];
}

- (void)socketIODidConnect:(SocketIO *)socket
{
    NSLog(@"DID CONNECT %@", socket);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DIODidConnect" object:nil];
}

- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    NSLog(@"DID DISCONNECT %@ %@", socket, error);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DIODidDisconnectWithError" object:nil];
    [self.socket connectToHost:DIOHost
                        onPort:DIOPort];
}

@end
