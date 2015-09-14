//
//  HTTPTimeOutManager.h
//  ECalendar-Pro
//
//  Created by etouch on 13-12-12.
//  Copyright (c) 2013年 etouch. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HTTPTimeOutDelegate <NSObject>
- (void)httpTimeOutConnection:(NSURLConnection*)httpConnection;
@end

@interface HTTPTimeOutManager : NSObject
@property (nonatomic,assign) id<HTTPTimeOutDelegate> delegate;
- (void)startMonitoringConnection:(NSURLConnection*)connection
                       forTimeout:(NSTimeInterval)timeout;
- (void)stopMonitoringConnection:(NSURLConnection *)connection;
@end
