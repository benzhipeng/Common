//
//  ServiceConfig.swift
//  ExpressMan
//
//  Created by zhipeng ben on 27/7/2015.
//  Copyright (c) 2015年 Tangram. All rights reserved.
//

import Foundation

enum WebServiceType : Int {
    
    case Query
    case Invalid
    
    func toString() -> String {
        
        var subPath = ""
        switch self {
        case .Query:
            subPath = "/query"
        case .Invalid:
            subPath = ""
            
        }
        return subPath
    }
}

class HttpRequestTool {
    
    class func apiAddressWithType(serviceType:WebServiceType) -> String{
        
        var  address = ""
        switch(serviceType) {
            case .Query:
                address = "http://www.kuaidi100.com"
            case .Invalid:
                address = "http://www.baidu.com"
        }
        address += serviceType.toString()
        return address
    }
    
    class func serviceID(serviceType:WebServiceType,param:[String:AnyObject]?) -> String {

        var serviceID = apiAddressWithType(serviceType)
        if  param == nil {
            return serviceID
        }
        
        let  keys = Array(param!.keys)
        for var i = 0; i < param!.count; i++ {
            let key = keys[i] as String
            let value = "\(param![key])"
            if  i == 0 {
                serviceID += "?"
            }else {
                serviceID += "&"
            }
            serviceID += key
            serviceID += "="
            serviceID += value
            
        }
        return serviceID
    }
}