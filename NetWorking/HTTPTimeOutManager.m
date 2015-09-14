//
//  HTTPTimeOutManager.m
//  ECalendar-Pro
//
//  Created by etouch on 13-12-12.
//  Copyright (c) 2013年 etouch. All rights reserved.
//

#import "HTTPTimeOutManager.h"

@interface HTTPTimeOutManager ()
@property (nonatomic,retain) NSTimer *timer;
@property (nonatomic,retain) NSMutableDictionary *connectionTimestampMap;
@property (nonatomic,retain) NSMutableDictionary *connectionTimeoutMap;
@end

@implementation HTTPTimeOutManager
@synthesize delegate = delegate_;
@synthesize timer = timer_;
@synthesize connectionTimestampMap = connectionTimestampMap_;
@synthesize connectionTimeoutMap = connectionTimeoutMap_;

- (id)init{
    self = [super init];
    if (self) {
        connectionTimestampMap_ = [[NSMutableDictionary alloc] init];
        connectionTimeoutMap_ = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc{
    delegate_ = nil;
    [timer_ release], timer_ = nil;
    [connectionTimestampMap_ release], connectionTimestampMap_ = nil;
    [connectionTimeoutMap_ release], connectionTimeoutMap_ = nil;
    [super dealloc];
}

- (void)handleConnectionTimeout:(NSURLConnection *)connection{
    [self stopMonitoringConnection:connection];
    [delegate_ httpTimeOutConnection:connection];
}

- (void)checkConnectionTimeout:(NSURLConnection *) connection forDate:(NSDate *)checkDate{
    id ucKey = [NSValue valueWithPointer:connection];
    NSDate *lastTimestamp = [self.connectionTimestampMap objectForKey:ucKey];
    NSTimeInterval timeout = [[self.connectionTimeoutMap objectForKey:ucKey] doubleValue];
    NSDate *timeoutTimestamp = [NSDate dateWithTimeInterval:timeout sinceDate:lastTimestamp];
    if ([timeoutTimestamp compare:checkDate] == NSOrderedAscending) {
        [self handleConnectionTimeout:connection];
    }
}

- (void)timerTick:(NSTimer *)timer{
    
    NSDate *now = [NSDate date];
    NSArray *keys = [self.connectionTimestampMap allKeys];
    for (id ucKey in keys) {
        NSURLConnection *connection = [ucKey pointerValue];
        [self checkConnectionTimeout:connection forDate:now];
    }
}

- (void)checkTimer{
    
    if(self.timer){
        if([self.connectionTimestampMap count] == 0){
            [self.timer invalidate];
            self.timer = nil;
        }
    }else{
        if ([self.connectionTimestampMap count] > 0) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                          target:self
                                                        selector:@selector(timerTick:)
                                                        userInfo:nil
                                                         repeats:YES];
        }
    }
}

- (void)startMonitoringConnection:(NSURLConnection*)connection
                       forTimeout:(NSTimeInterval)timeout{
    id  ucKey  = [NSValue valueWithPointer:connection];
    [self.connectionTimeoutMap setObject:[NSNumber numberWithDouble:timeout] forKey:ucKey];
    [self.connectionTimestampMap setObject:[NSDate date] forKey:ucKey];
    [self checkTimer];
    
}

- (void)stopMonitoringConnection:(NSURLConnection *)connection{
    
    id ucKey = [NSValue valueWithPointer:connection];
    [self.connectionTimestampMap removeObjectForKey:ucKey];
    [self.connectionTimeoutMap removeObjectForKey:ucKey];
    [self checkTimer];
    
}

@end
