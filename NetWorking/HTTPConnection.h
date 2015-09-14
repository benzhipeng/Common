//
//  HTTPConnection.h
//
//  Created by ben on 12-10-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>
#import "ETXmlParser.h"
#import "HTTPRequest.h"
#import "HTTPTimeOutManager.h"
#import "NetworkUtil.h"
#define deaultTimeOut  20

enum kRequestStatus {
    kRequestStatusFinished ,
    kRequestStatusFailed ,
    kRequestStatusTimeOut,
    kRequestStatusDataReceived,
    kRequestStatusResponsed,
    kRequestStatusNoNet
};
#define  MAXNUMBER_HTTPCONNECTION           30
@protocol HTTPConnectionDelegate;

#if NS_BLOCKS_AVAILABLE
typedef void (^HTTPRequestBlock)(HTTPRequest*  httpRequest);
#endif


@interface HTTPConnection : NSObject {
    
    int _numberOfHTTPConnection;
    NSMutableArray *_marrayTaskDic;
    HTTPTimeOutManager* httpTimeOutManager;
    HTTPRequestBlock  httpRequestBlock;
}
@property (nonatomic, assign) id <HTTPConnectionDelegate> delegate;

/**
 *  异步发出一个请求
 *
 *  @param strURL   发出的请求的地址
 *  @param dicParam 请求的参数 标识该请求 key为"type"
 *
 *  @return 创建该请求是否成功
 */
- (BOOL)requestWebDataWithURL:(NSString *)strURL andParam:(NSDictionary *)dicParam;

/**
 *  异步发出一个请求
 *
 *  @param request  外部传进来一个request对象
 *  @param dicParam 请求的参数 标识该请求
 *
 *  @return 创建该请求是否成功
 */
- (BOOL)requestWebDataWithRequest:(NSURLRequest *)request andParam:(NSDictionary *)dicParam;

//--------------两个方法暂未加上超时处理,暂不用--------------------------------
/**
 *  同步发出一个请求
 *
 *  @param request 外部传进来一个request对象
 *
 *  @return 创建该请求是否成功 YES OR NO
 */
+ (HTTPRequest*)synchronousDataWithRequest:(NSURLRequest *)request;

/**
 *  同步发出一个请求
 *
 *  @param strURL 发出的请求的地址
 *
 *  @return 创建该请求是否成功
 */
+ (HTTPRequest*)synchronousDataWithURL:(NSString*)strURL;

//--------------两个方法暂未加上超时处理,暂不用--------------------------------


/**
 *  指定取消某一个当前正在运行的请求
 *
 *  @param dicParam 请求的参数 标识该请求 key为"type"
 *
 *  @return 取消请求是否成功
 */
- (BOOL)cancelRequest:(NSDictionary *)dicParam;

/**
 *  取消全部请求
 */
- (void)clearRequest;

/**
 *  执行block来替代delegate实现回调的处理
 *
 *  @param httpBlock 处理的代码块
 */
- (void)setHttpRequestBlock:(HTTPRequestBlock)httpBlock;
@end

@protocol HTTPConnectionDelegate <NSObject>

@optional
- (void)httpConnect:(HTTPConnection*)httpConnect _httpRequest:(HTTPRequest*)httpRequest;
@end
