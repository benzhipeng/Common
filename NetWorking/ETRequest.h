//
//  ETRequest.h
//  ECalendar-Pro
//
//  Created by etouch on 13-6-22.
//  Copyright (c) 2013年 etouch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPRequest.h"
@interface ETRequest : NSObject

@property (nonatomic,retain) HTTPRequest*   et_httprequest;
@property (nonatomic,retain) id             et_data;
@property (nonatomic,assign) BOOL           et_isLocal;
@end