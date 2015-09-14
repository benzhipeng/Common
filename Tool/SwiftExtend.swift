//
//  SwiftExtend.swift
//  ExpressMan
//
//  Created by zhipeng ben on 15/7/24.
//  Copyright (c) 2015年 Tangram. All rights reserved.
//

extension Array {
    func indexOf<T: Equatable>(x: T) -> Int? {
        for i in 0...self.count {
            if self[i] as! T == x {
                return i
            }
        }
        return nil
    }
    
    
    
}