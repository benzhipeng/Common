//
//  HTTPRequest.h
//  ECalendar-Pro
//
//  Created by etouch on 13-6-22.
//  Copyright (c) 2013年 etouch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTTPRequest : NSObject

@property (nonatomic,assign) int httprequest_status; //http 请求状态 结束，中，响应，失败,，没有网络链接
@property (nonatomic,retain) NSDictionary*  httprequest_param; //用于标示没一个请求 @"type"为key
@property (nonatomic,assign) NSInteger      httprequest_response_status; //请求响应的头状态
@property (nonatomic,retain) NSDictionary*  httprequest_response_head; //头的信息
@property (nonatomic,retain) NSError*       httprequest_error; //错误信息
@property (nonatomic,retain) NSData*        httprequest_data; //每次接受的数据部分
@property (nonatomic,retain) NSMutableData* httprequest_totaldata; //总共从服务器接收到的数据
@end