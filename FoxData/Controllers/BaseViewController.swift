//
//  BaseViewController.swift
//  FoxData
//
//  Created by Zach Wang on 2019/1/13.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import UIColor_Hex_Swift

class BaseViewController: UIViewController  {

    var topMargin:CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.navigationController?.navigationBar.isTranslucent = true
        self.view.backgroundColor = UIColor.init(white: 0.95, alpha: 1)
        // Do any additional setup after loading the view.

        if self.navigationController == nil{
            topMargin = UIApplication.shared.statusBarFrame.height
        }else {
            topMargin = self.navigationController!.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.height
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layoutAllSubviews(self.traitCollection.horizontalSizeClass == .compact)
    }
    
    /// 用来判断是否是手机竖屏(iPad分割小屏)模式
    open func layoutAllSubviews(_ isWidthCompactLayout:Bool){
        
    }
    
}

extension UIViewController : NVActivityIndicatorViewable {
    private var navItemWH:CGFloat{
        return 22
    }
    
    func showLoading(_ title:String = "Processing..."){
        let size = CGSize(width: 30, height: 30)
        self.startAnimating(size, message: title, type: NVActivityIndicatorType.lineScale, fadeInAnimation: nil)
    }
    
    func hideLoading(){
        self.stopAnimating(nil)
    }
    
    func generateNavBarIconItem(imageName:String, target:Any?, action:Selector, tintColor:UIColor = UIColor.init("#1296db")) -> UIBarButtonItem{
        let frame = CGRect.init(x: 0, y: 0, width: navItemWH + 10, height: navItemWH)
        let button = UIButton.init(type: .roundedRect)
        button.frame = frame
        button.setImage(UIImage.init(named: imageName), for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = tintColor
        let view = UIView.init(frame: frame)
        view.addSubview(button)
        let item = UIBarButtonItem.init(customView: view)
        return item
    }
    
    func showMessagePop(_ title:String, _ message:String?){
        var msg = message
        if msg == nil{
            msg = title
        }
        AJMessage.show(title: title, message: msg!, position: .top, status: .info)
    }
    
    func showSuccessPop(_ title:String, _ message:String?){
        var msg = message
        if msg == nil{
            msg = title
        }
        AJMessage.show(title: title, message: msg!, position: .top, status: .success)
    }
    
    func showFailurePop(_ title:String, _ message:String?){
        var msg = message
        if msg == nil{
            msg = title
        }
        AJMessage.show(title: title, message: msg!, position: .top, status: .error)
    }
}
