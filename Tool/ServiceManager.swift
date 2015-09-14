//
//  ServiceManager.swift
//  ExpressMan
//
//  Created by zhipeng ben on 24/7/2015.
//  Copyright (c) 2015年 Tangram. All rights reserved.
//

import Foundation

private let ServiceManagerRequestFinishedNotification   = "ServiceManagerRequestFinishedNotification"
private let ServiceManagerRequestFailedNotification     = "ServiceManagerRequestFailedNotification"

typealias WebServiceID = String

private let  KWebServiceServiceID   = "ServiceID"
private let  KWebServiceUserInfo    = "UserInfo"
private let  KWebServiceResponse    = "Response"
private let  KWebServiceError       = "Error"


internal protocol SerivceCallbackDelegate:NSObjectProtocol{
    
    func requestFinished(serviceID:WebServiceID,response:AnyObject,userInfo:[NSObject : AnyObject]?)
    
    func requestFailed(serviceID:WebServiceID,error:NSError,userInfo:[NSObject : AnyObject]?)
}

internal protocol SerivceManagerDelegate:NSObjectProtocol {
    
    func service(serviceID:WebServiceID,callbackWithData data:AnyObject,userInfo:[NSObject : AnyObject]?)
    
    func service(serviceID:WebServiceID,requestFailed error:NSError,userInfo:[NSObject : AnyObject]?)
}



private var kObjectServiceKey = 0

extension NSObject:SerivceManagerDelegate {
    
    private class ServiceManager: NSObject,SerivceCallbackDelegate {
        
        lazy var serviceDictionary = [String:HttpRequestService]()
        static let sharedInstance:ServiceManager = ServiceManager()
        func request(serviceType:WebServiceType,param:[String:AnyObject]?,method:Alamofire.Method,userInfo:[NSObject : AnyObject]?) -> WebServiceID?{
            let serviceID:String = HttpRequestTool.serviceID(serviceType, param: param)
            if  let _: HttpRequestService = self.serviceDictionary[serviceID] {
                return nil
            }
            
            let service = HttpRequestService(serviceType: serviceType, param: param, userInfo: userInfo, delegate: self)
            service.serviceID = serviceID
            service.startRequest(method)
            self.serviceDictionary[serviceID] = service
            return serviceID
        }
        
        
        func cancelRequestWithServiceID(serviceID:WebServiceID) {
            self.serviceDictionary.removeValueForKey(serviceID)
        }
        
        
        func requestFailed(serviceID: WebServiceID, error: NSError, userInfo: [NSObject : AnyObject]?) {
            var userInfos = [String:AnyObject]()
            userInfos[KWebServiceServiceID] = serviceID
            userInfos[KWebServiceError] = error
            userInfos[KWebServiceUserInfo] = userInfo
            NSNotificationCenter.defaultCenter().postNotificationName(ServiceManagerRequestFailedNotification, object: userInfos)
            self.serviceDictionary.removeValueForKey(serviceID)
        }
        
        
        func requestFinished(serviceID: WebServiceID, response: AnyObject, userInfo: [NSObject : AnyObject]?) {
            var userInfos = [String:AnyObject]()
            userInfos[KWebServiceServiceID] = serviceID
            userInfos[KWebServiceResponse] = response
            userInfos[KWebServiceUserInfo] = userInfo
            NSNotificationCenter.defaultCenter().postNotificationName(ServiceManagerRequestFinishedNotification, object: userInfos)
            self.serviceDictionary.removeValueForKey(serviceID)
            
        }
    }
    
    private class HttpRequestService {
        
        var  request:Request?
        var serviceID:WebServiceID = ""
        
        var serviceType:WebServiceType?
        var param:[String : AnyObject]?
        var userInfo:[NSObject : AnyObject]?
        weak var delegate:SerivceCallbackDelegate?
        
        init(serviceType:WebServiceType,param:[String : AnyObject]?,userInfo:[NSObject : AnyObject]?,delegate:SerivceCallbackDelegate){
            
            self.param = param
            self.serviceType = serviceType
            self.delegate = delegate
            self.userInfo = userInfo
        }
        
        
        func startRequest(method:Alamofire.Method){

            let url:String = HttpRequestTool.apiAddressWithType(self.serviceType!)
            self.request = Alamofire.request(method, url.URLString, parameters: self.param, encoding: .URL, headers: nil).responseJSON(completionHandler: { [weak self] (urlRequest, urlResponse, result) -> Void in
                if  let mDelegate = self?.delegate {
                    if  result.isSuccess {
                        if mDelegate.respondsToSelector(Selector("requestFinished:response:userInfo:")) {
                            mDelegate.requestFinished(self!.serviceID, response: (result.data)!, userInfo: self?.userInfo)
                        }
                    }else {
                        if mDelegate.respondsToSelector(Selector("requestFailed:error:userInfo:")) {
                            mDelegate.requestFailed(self!.serviceID, error:(result.error as! NSError), userInfo: self?.userInfo)
                        }

                    }
                }
            })
        }
    }

    
    private class ServiceObjectHelper {
        
        var delegate:SerivceManagerDelegate?
        lazy var idDictionary = [String:String]()
        deinit {
            
            if  self.idDictionary.count > 0 {
                for sid in self.idDictionary.keys {
                    ServiceManager.sharedInstance.cancelRequestWithServiceID(sid)
                }
            }
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
        
        
        func cleanService(serviceID:WebServiceID){
            
            for  sid in self.idDictionary.keys {
                if  sid == serviceID {
                    self.idDictionary.removeValueForKey(sid)
                }
            }
            
            if  self.idDictionary.count == 0 {
                NSNotificationCenter.defaultCenter().removeObserver(self, name: ServiceManagerRequestFinishedNotification, object: nil)
                NSNotificationCenter.defaultCenter().removeObserver(self, name: ServiceManagerRequestFailedNotification, object: nil)
            }
        }
        
        @objc private func serviceRequestFinished(notification:NSNotification){
            
            var userInfos = notification.object as! [String:AnyObject]
            var bMyService = false
            for sid in self.idDictionary.keys {
                if sid == (userInfos[KWebServiceServiceID] as! WebServiceID) {
                    bMyService = true
                    break
                }
            }
            
            let userInfo = userInfos[KWebServiceUserInfo] as? [NSObject : AnyObject]
            if (bMyService == false) {
                return
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                if let mDelegate = self.delegate {
                    if mDelegate.respondsToSelector(("service:callbackWithData:userInfo:")) {
                        mDelegate.service(userInfos[KWebServiceServiceID] as! WebServiceID, callbackWithData: userInfos[KWebServiceResponse]!, userInfo: userInfo)
                    }
                }
                self.cleanService(userInfos[KWebServiceServiceID] as! WebServiceID)
            })
        }
        
        @objc private func serviceRequestFailed(notification:NSNotification){
            
            var userInfos = notification.object as! [String:AnyObject]
            var bMyService = false
            for sid in self.idDictionary.keys {
                if sid == (userInfos[KWebServiceServiceID] as! WebServiceID) {
                    bMyService = true
                    break
                }
            }
            let userInfo = userInfos[KWebServiceUserInfo] as? [NSObject : AnyObject]
            if (bMyService == false) {
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let mDelegate = self.delegate {
                    if mDelegate.respondsToSelector(("service:requestFailed:userInfo:")) {
                        mDelegate.service(userInfos[KWebServiceServiceID] as! WebServiceID, requestFailed: userInfos[KWebServiceError] as! NSError, userInfo: userInfo)
                    }
                }
                self.cleanService(userInfos[KWebServiceServiceID] as! WebServiceID)
            })
        }
    }

    
    func makeRequestForType(type:WebServiceType,param:[String:AnyObject]?,method:Alamofire.Method,userInfo:[NSObject : AnyObject]?) {
        var serviceHelper = objc_getAssociatedObject(self, &kObjectServiceKey) as? ServiceObjectHelper
        if serviceHelper == nil {
            serviceHelper = ServiceObjectHelper()
            serviceHelper?.delegate = self
            objc_setAssociatedObject(self, &kObjectServiceKey, serviceHelper, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        if  serviceHelper?.idDictionary.count == 0 {
            NSNotificationCenter.defaultCenter().addObserver(serviceHelper!, selector: Selector("serviceRequestFinished:"), name: ServiceManagerRequestFinishedNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(serviceHelper!, selector: Selector("serviceRequestFailed:"), name: ServiceManagerRequestFailedNotification, object: nil)
            
        }
        let sid = ServiceManager.sharedInstance.request(type, param: param, method: method, userInfo: userInfo)
        if  sid != nil {
            serviceHelper?.idDictionary[sid!] = "\(type.rawValue)"
        }
    }
    
    
    func getServiceTypeByID(serviceID:WebServiceID) -> WebServiceType{
        
        var serviceType = WebServiceType.Invalid
        let serviceHelper = objc_getAssociatedObject(self, &kObjectServiceKey) as? ServiceObjectHelper
        if  serviceHelper != nil {
            if  let tmp:String? = serviceHelper?.idDictionary[serviceID] {
                serviceType =  WebServiceType(rawValue: Int(tmp!)!)!
            }
        }
        return serviceType
    }
    
    
    func  runningServices(type:WebServiceType) -> [WebServiceID]{
        
        var  result = [WebServiceID]()
        let serviceHelper = objc_getAssociatedObject(self, &kObjectServiceKey) as? ServiceObjectHelper
        if  serviceHelper != nil {
            for  serviceID in serviceHelper!.idDictionary.keys {
                if  let tmp = serviceHelper!.idDictionary[serviceID]{
                    let serviceType =  WebServiceType(rawValue: Int(tmp)!)!
                    if  serviceType == type {
                        result.append(serviceID)
                    }
                }
            }
        }
        return result
    }
    
    
    func service(serviceID: WebServiceID, callbackWithData data: AnyObject, userInfo: [NSObject : AnyObject]?) {

        

//        print(data)
//        var  result = self.runningServices(.Query)
//        
//        print(result)
//        
//        var serviceType = self.getServiceTypeByID(serviceID) as WebServiceType
//        
//        println(serviceType.rawValue)
        
        
        
        
        
    }
    
    func service(serviceID: WebServiceID, requestFailed error: NSError, userInfo: [NSObject : AnyObject]?) {
        
        print(error)

    }
}

