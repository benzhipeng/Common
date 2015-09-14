//
//  HTTPConnection.m
//
//  Created by ben on 12-10-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "HTTPConnection.h"


@interface HTTPConnection (Private)<HTTPTimeOutDelegate>
- (void)startHTTPConnection;
@end

@implementation HTTPConnection
@synthesize delegate;
- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization.
        _numberOfHTTPConnection = 0;
        _marrayTaskDic = [[NSMutableArray alloc] initWithCapacity:5];
        httpTimeOutManager = [[HTTPTimeOutManager alloc] init];
        httpTimeOutManager.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    //清空任务
    [self clearRequest];
    
    delegate = nil;
    if(httpRequestBlock){
        [httpRequestBlock release];
        httpRequestBlock = nil;
    }
    [_marrayTaskDic release];
    [httpTimeOutManager release];
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (BOOL)requestWebDataWithURL:(NSString *)strURL andParam:(NSDictionary *)dicParam
{
    if (nil == dicParam) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:strURL];
    NSMutableURLRequest*    request = [[NSMutableURLRequest alloc]initWithURL:url];
    BOOL success = [self requestWebDataWithRequest:request andParam:dicParam];
    [request release];
    return success;
}

- (BOOL)requestWebDataWithRequest:(NSURLRequest *)request andParam:(NSDictionary *)dicParam {
    
    if (nil == dicParam) {
        return NO;
    }
    //请求类型必须存在
    if (nil == [dicParam objectForKey:@"type"]) {
        //HTTPLOG(@"任务参数不足");
        return NO;
    }
    //正在处理或等待处理的任务不再接收
    for (NSDictionary *dicTask in _marrayTaskDic) {
        //
        HTTPRequest*      etRequest = (HTTPRequest*)[dicTask objectForKey:@"httprequest"];
        if ([dicParam isEqualToDictionary:etRequest.httprequest_param]) {
            //HTTPLOG(@"任务重复:%@", dicParam);
            return NO;
        }
    }
    NSMutableDictionary *mdicTask = [[NSMutableDictionary alloc] initWithCapacity:2];
    //创建HTTP网络连接
    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [mdicTask setObject:urlConnection forKey:@"connect"];
    [urlConnection release];
    
    //创建ETRequest用于保存网络请求回调的信息
    HTTPRequest*      etRequest = [[HTTPRequest alloc]init];
    //设置参数
    etRequest.httprequest_param = dicParam;
    [mdicTask setObject:etRequest forKey:@"httprequest"];
    [etRequest release];
    //保存到数组
    [_marrayTaskDic addObject:mdicTask];
    
    //添加到timeout manager中
    [httpTimeOutManager startMonitoringConnection:urlConnection forTimeout:deaultTimeOut];
    
    if([NetworkUtil sharedManager].netType == ETNetNoReachable){ //无网络连接
        
        etRequest.httprequest_status = kRequestStatusNoNet;
        [self responseConnection:urlConnection _httpRequest:etRequest];
        [_marrayTaskDic removeObject:mdicTask];
        [mdicTask release];
        return NO;
    }
    [mdicTask release];
    [self startHTTPConnection];
    return YES;
}


+ (HTTPRequest*)synchronousDataWithRequest:(NSURLRequest *)request{
    
    NSURLResponse* response = nil;
    NSError*       error = nil;
    HTTPRequest*        httpRequest = [[HTTPRequest alloc] init];
    NSData*  reciveData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(response == nil){
        httpRequest.httprequest_status = kRequestStatusFailed;
    }else {
        if ([response isMemberOfClass:NSHTTPURLResponse.class]) {
            NSHTTPURLResponse *responseHTTP = (NSHTTPURLResponse *)response;
            NSUInteger statusCode = responseHTTP.statusCode;
            NSDictionary *dicAllHeaderFields = responseHTTP.allHeaderFields;
            httpRequest.httprequest_response_head = dicAllHeaderFields;
            if(statusCode != 200){
                httpRequest.httprequest_status = kRequestStatusFailed;
            }else {
                if(reciveData == nil || reciveData.length <= 0){
                    httpRequest.httprequest_status = kRequestStatusFailed;
                }else {
                    httpRequest.httprequest_totaldata = [NSMutableData dataWithData:reciveData];
                    httpRequest.httprequest_status = kRequestStatusFinished;
                }
            }
        }
    }
    return [httpRequest autorelease];
}

+ (HTTPRequest*)synchronousDataWithURL:(NSString*)strURL{
    
    NSURL *url = [NSURL URLWithString:strURL];
    NSMutableURLRequest*    request = [[[NSMutableURLRequest alloc]initWithURL:url] autorelease];
    return [[self class] synchronousDataWithRequest:request];
}

//取消网络请求
- (BOOL)cancelRequest:(NSDictionary *)dicParam
{
    if (nil == dicParam) {
        return NO;
    }
    
    if((nil != dicParam) && ([dicParam objectForKey:@"type"] == nil|| [[dicParam objectForKey:@"type"] isEqualToString:@""])){
        return NO;
    }
    //遍历所有任务
    for (int i = 0; i < _marrayTaskDic.count; i++) {
        //查看任务是否相同
        NSDictionary *dicTask = [_marrayTaskDic objectAtIndex:i];
        HTTPRequest*      etRequest = (HTTPRequest*)[dicTask objectForKey:@"httprequest"];
        if ([dicParam isEqualToDictionary:etRequest.httprequest_param]) {
            //取消网络请求
            NSURLConnection *connect = [dicTask objectForKey:@"connect"];
            [httpTimeOutManager stopMonitoringConnection:connect];
            [connect cancel];
            //从任务队列中删除
            [_marrayTaskDic removeObjectAtIndex:i];
            _numberOfHTTPConnection -= 1;
            return YES;
        }
    }
    return NO;
}

//清空网络请求
- (void)clearRequest
{
    //遍历所有任务
    for (NSDictionary *dicTask in _marrayTaskDic) {
        NSURLConnection *connect = [dicTask objectForKey:@"connect"];
        [httpTimeOutManager stopMonitoringConnection:connect];
        [connect cancel];
        _numberOfHTTPConnection -= 1;
        if(_numberOfHTTPConnection < 0){
            _numberOfHTTPConnection = 0;
        }
    }
    //从任务队列中删除
    [_marrayTaskDic removeAllObjects];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)setHttpRequestBlock:(HTTPRequestBlock)httpBlock{
    
    if(httpRequestBlock){
        [httpRequestBlock release];
        httpRequestBlock = nil;
    }
    httpRequestBlock = [httpBlock copy];
}

- (void)responseConnection:(NSURLConnection*)connection _httpRequest:(HTTPRequest*)httpRequest{
    
    if(httpRequest.httprequest_status == kRequestStatusFailed ||
       httpRequest.httprequest_status == kRequestStatusFinished ||
       httpRequest.httprequest_status == kRequestStatusNoNet){
        [httpTimeOutManager stopMonitoringConnection:connection];
    }
#if NS_BLOCKS_AVAILABLE
    if(httpRequestBlock){
        httpRequestBlock(httpRequest);
    }
#endif
    if (delegate != nil &&  [delegate respondsToSelector:@selector(httpConnect:_httpRequest:)]) {
        [delegate httpConnect:self _httpRequest:httpRequest];
    }
}

#pragma mark - HTTPTimeOutDelegate
- (void)httpTimeOutConnection:(NSURLConnection *)httpConnection{
    
    NSDictionary *dicTask = nil;
    for (int i = 0; i < _marrayTaskDic.count; i++) {
        NSDictionary *dic = [_marrayTaskDic objectAtIndex:i];
        //找到网络连接相应的数据字典
        if ([dic objectForKey:@"connect"] == httpConnection) {
            dicTask = dic;
            break;
        }
    }
    if (dicTask) {
        [dicTask retain];
        //删除
        [httpConnection cancel];
        [_marrayTaskDic removeObject:dicTask];
        HTTPRequest*    etRequest =  (HTTPRequest*)[dicTask objectForKey:@"httprequest"];
        etRequest.httprequest_status = kRequestStatusTimeOut;
        [self responseConnection:httpConnection _httpRequest:etRequest];
        [dicTask release];
        _numberOfHTTPConnection -= 1;
    }
    [self startHTTPConnection];
}

#pragma mark -
#pragma mark NSURLConnectionDataDelegate

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSDictionary *dicTask = nil;
    for (int i = 0; i < _marrayTaskDic.count; i++) {
        NSDictionary *dic = [_marrayTaskDic objectAtIndex:i];
        //找到网络连接相应的数据字典
        if ([dic objectForKey:@"connect"] == connection) {
            dicTask = dic;
            break;
        }
    }
    if (dicTask){
        [dicTask retain];
        //删除
        [_marrayTaskDic removeObject:dicTask];
        HTTPRequest*    etRequest =  (HTTPRequest*)[dicTask objectForKey:@"httprequest"];
        etRequest.httprequest_status = kRequestStatusFailed;
        etRequest.httprequest_error = error;
        [self responseConnection:connection _httpRequest:etRequest];
        [dicTask release];
        _numberOfHTTPConnection -= 1;
    }
    [self startHTTPConnection];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSDictionary *dicTask = nil;
    for (int i = 0; i < _marrayTaskDic.count; i++) {
        NSDictionary *dic = [_marrayTaskDic objectAtIndex:i];
        //找到网络连接相应的数据字典
        if ([dic objectForKey:@"connect"] == connection) {
            dicTask = dic;
            break;
        }
    }
    if ([response isMemberOfClass:NSHTTPURLResponse.class]) {
        NSHTTPURLResponse *responseHTTP = (NSHTTPURLResponse *)response;
        NSUInteger statusCode = responseHTTP.statusCode;
        NSDictionary *dicAllHeaderFields = responseHTTP.allHeaderFields;
        
        HTTPRequest*    etRequest =  (HTTPRequest*)[dicTask objectForKey:@"httprequest"];
        etRequest.httprequest_response_head = dicAllHeaderFields;
        etRequest.httprequest_response_status = statusCode;
        etRequest.httprequest_status = kRequestStatusResponsed;
        if(statusCode != 200){
            
            etRequest.httprequest_status = kRequestStatusFailed;
            [self responseConnection:connection _httpRequest:etRequest];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSDictionary *dicTask = nil;
    for (int i = 0; i < _marrayTaskDic.count; i++) {
        NSDictionary *dic = [_marrayTaskDic objectAtIndex:i];
        //找到网络连接相应的数据字典
        if ([dic objectForKey:@"connect"] == connection) {
            dicTask = dic;
            break;
        }
    }
    if (dicTask) {
        //向缓存中添加数据
        HTTPRequest*    etRequest =  (HTTPRequest*)[dicTask objectForKey:@"httprequest"];
        etRequest.httprequest_status = kRequestStatusDataReceived;
        etRequest.httprequest_data = data;
        [etRequest.httprequest_totaldata appendData:data];
        [self responseConnection:connection _httpRequest:etRequest];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSDictionary *dicTask = nil;
    for (int i = 0; i < _marrayTaskDic.count; i++) {
        NSDictionary *dic = [_marrayTaskDic objectAtIndex:i];
        //找到网络连接相应的数据字典
        if ([dic objectForKey:@"connect"] == connection) {
            dicTask = dic;
            break;
        }
    }
    if (dicTask) {
        [dicTask retain];
        //删除
        [_marrayTaskDic removeObject:dicTask];
        HTTPRequest*    etRequest =  (HTTPRequest*)[dicTask objectForKey:@"httprequest"];
        etRequest.httprequest_status = kRequestStatusFinished;
        [self responseConnection:connection _httpRequest:etRequest];
        [dicTask release];
        dicTask = nil;
        _numberOfHTTPConnection -= 1;
    }
    [self startHTTPConnection];
}


#pragma mark - Private
- (void)startHTTPConnection {
    if (_numberOfHTTPConnection < MAXNUMBER_HTTPCONNECTION) {
        
        if(_numberOfHTTPConnection < _marrayTaskDic.count) {
            NSDictionary *dicTask = [_marrayTaskDic objectAtIndex:_numberOfHTTPConnection];
            NSURLConnection *urlConnection = [dicTask objectForKey:@"connect"];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            [urlConnection start];
            _numberOfHTTPConnection += 1;
        }else {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
    }
}
@end


