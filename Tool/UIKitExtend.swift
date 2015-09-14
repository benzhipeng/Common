//
//  UIKitExtend.swift
//  ExpressMan
//
//  Created by zhipeng ben on 15/7/21.
//  Copyright (c) 2015年 Tangram. All rights reserved.
//

import UIKit

public typealias UIButtonPressedBlock = (() -> Void)
private var kUIButtonPressedKey = 0

// MARK: - 将按钮的点击事件封装成block
extension UIButton {
    
    private class UIButtonClosureWrapper {
        var closure: UIButtonPressedBlock?
        init(closure: UIButtonPressedBlock?) {
            self.closure = closure
        }
    }

    public func pressedDoBlock(block:UIButtonPressedBlock) {
        self.addTarget(self, action: Selector("buttonPressed:"), forControlEvents: UIControlEvents.TouchUpInside)
        objc_setAssociatedObject(self, &kUIButtonPressedKey,UIButtonClosureWrapper(closure: block), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    @objc private func buttonPressed(sender:UIButton){
        
        if let block = objc_getAssociatedObject(self, &kUIButtonPressedKey) as? UIButtonClosureWrapper {
            if let inBlock = block.closure{
                inBlock()
            }
        }
    }
}


// MARK: - 倒计时用的button
extension UIButton {
    
    public func startTime(var timeOut:Int,title:String,waitTitle:String){
    
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue) as dispatch_source_t
        dispatch_source_set_timer(timer,dispatch_walltime(nil, 0), 1 * NSEC_PER_SEC, 0)
        dispatch_source_set_event_handler(timer, { () -> Void in
            
            if timeOut <= 0 {
                dispatch_source_cancel(timer)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.setTitle(title, forState: UIControlState.Normal)
                    self.userInteractionEnabled = true
                })
                
            }else {
                var seconds = timeOut % 60
                if  seconds == 0 {
                    seconds = timeOut
                }
                let strTime = "\(seconds)"
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.setTitle(waitTitle + strTime, forState: UIControlState.Normal)
                    self.userInteractionEnabled = false
                })
                timeOut--
            }
        })
        dispatch_resume(timer)
    }
    
}


private var KUITextFieldLimitLengthKey = 0
// MARK: - 限制文本框长度
extension UITextField {
    
    var limitLength: Int {
        get {
            return (objc_getAssociatedObject(self, &KUITextFieldLimitLengthKey)  as! NSNumber).integerValue
        }
        set {
            objc_setAssociatedObject(self, &KUITextFieldLimitLengthKey,NSNumber(integer: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.addTarget(self, action: Selector("textFieldTextLengthLimit"), forControlEvents: UIControlEvents.EditingChanged)
        }
    }
    
    
    @objc private func textFieldTextLengthLimit() {
        
        let len = self.limitLength as Int
        var isChinese = false
        if self.textInputMode!.primaryLanguage == "en-US" {
            isChinese = false
        }else {
            isChinese = true
        }
        let str = self.text!.stringByReplacingOccurrencesOfString("?", withString: "", options:[], range: nil) as String
        if isChinese {
            let selectedRange = self.markedTextRange
            let position = self.positionFromPosition(selectedRange!.start, offset: 0)
            if  position != nil {

                if str.characters.count >= len {
                    self.text = (str as NSString).substringToIndex(len)
                }
            }
        }else {
            if str.length >= len {
                self.text = (str as NSString).substringToIndex(len)
            }
        }
    }
}


// MARK: - 根据xib获取UIView的实例
extension UIView {
    
    class func instanceFromNib(nibName:String) -> UIView?{
        
        var result:UIView?
        
        let elements = NSBundle.mainBundle().loadNibNamed(nibName, owner: self, options: nil)
        for  obj in elements {
            if  obj.isKindOfClass(self) {
                result = obj as? UIView
                break
            }
        }
        return result
    }
}

extension UIView {
    
    func viewController() -> UIViewController? {
        let responser:UIResponder? = self.nextResponder()!
        while  (responser != nil) {
            if(responser!.isKindOfClass(UIViewController.self)) {
                return responser as? UIViewController
            }
        }
        return responser as? UIViewController
    }
}

extension UIColor {

    private class func colorComponentFrom(string:String,start:Int,length:Int) -> CGFloat{
        
        let subString = (string as NSString).substringWithRange(NSMakeRange(start, length))
        let fullHex = subString
        var hexComponent:UInt32 = 0
        NSScanner(string: fullHex).scanHexInt(&hexComponent)
        return CGFloat(hexComponent) / 255.0;
    }
    
    class func colorWithHexString(hexString:String) -> UIColor{
        
        _ = hexString.stringByReplacingOccurrencesOfString("#", withString: "", options: [], range: nil)
        let red =  colorComponentFrom(hexString, start: 0, length: 2)
        let green =  colorComponentFrom(hexString, start: 2, length: 2)
        let blue =  colorComponentFrom(hexString, start: 4, length: 2)
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}


typealias UIAlertControllerCompletionBlock = ((buttonIndex:Int) -> Void)
extension UIAlertController {

    
    class func show(alertController:UIAlertController,presentController:UIViewController,title:String,message:String,cancleTitle:String,otherTitles:[String],tapBlock:UIAlertControllerCompletionBlock){
        
        let cancelAction = UIAlertAction(title: cancleTitle, style: .Cancel) { (action) in
            tapBlock(buttonIndex: 0)
        }
        alertController.addAction(cancelAction)
        for  title in otherTitles {
            let action = UIAlertAction(title: title, style: .Default) { (action) in
                let index = otherTitles.indexOf(title)! + 1
                tapBlock(buttonIndex: index)
            }
            alertController.addAction(action)
        }
        presentController.presentViewController(alertController, animated: true) {
            
        }
    }
    
    class  func showActionSheet(presentController:UIViewController,title:String,message:String,cancleTitle:String,otherTitles:[String],tapBlock:UIAlertControllerCompletionBlock) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
        show(alertController, presentController: presentController, title: title, message: message, cancleTitle: cancleTitle, otherTitles: otherTitles, tapBlock: tapBlock)
    }
    
    class func showAlertView(presentController:UIViewController,title:String,message:String,cancleTitle:String,otherTitles:[String],tapBlock:UIAlertControllerCompletionBlock){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        show(alertController, presentController: presentController, title: title, message: message, cancleTitle: cancleTitle, otherTitles: otherTitles, tapBlock: tapBlock)
    }
}