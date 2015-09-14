//
//  HTTPRequest.m
//  ECalendar-Pro
//
//  Created by etouch on 13-6-22.
//  Copyright (c) 2013年 etouch. All rights reserved.
//

#import "HTTPRequest.h"

@implementation HTTPRequest
@synthesize httprequest_data;
@synthesize httprequest_error;
@synthesize httprequest_param;
@synthesize httprequest_response_head;
@synthesize httprequest_response_status;
@synthesize httprequest_status;
@synthesize httprequest_totaldata;

- (id)init{
    
    if(self = [super init]){
        
        httprequest_totaldata = [[NSMutableData alloc]init];
        httprequest_data = nil;
        httprequest_param = nil;
        httprequest_error = nil;
        httprequest_response_head = nil;
        httprequest_response_status = 0;
    }
    return self;
}
- (void)dealloc{
    
    //NSLog(@"\n\n****httpConnection dealloc****\n\n");
    
    [httprequest_totaldata release];
    [httprequest_data release];
    [httprequest_error release];
    [httprequest_param release];
    [httprequest_response_head release];
    [super dealloc];
}
@end
