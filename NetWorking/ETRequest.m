//
//  ETRequest.m
//  ECalendar-Pro
//
//  Created by etouch on 13-6-22.
//  Copyright (c) 2013年 etouch. All rights reserved.
//

#import "ETRequest.h"

@implementation ETRequest

@synthesize et_data;
@synthesize et_httprequest;
@synthesize et_isLocal;

- (void)dealloc{
    
    [et_data release];
    [et_httprequest release];
    [super dealloc];
}

@end
