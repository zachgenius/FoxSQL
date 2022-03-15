//
//  SideMenu.swift
//  FoxData
//
//  Created by Zach Wang on 4/11/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit

class SideMenu: UIView {

    private var tapRecognizer:UITapGestureRecognizer?
    
    ///用于展示的菜单, 讲需要展示的view插入这里
    private let contentView:UIView = UIView()
    private let overlayView:UIView = UIView()
    private var addedContentView:UIView?
    
    var menuWidth:CGFloat = 0 {
        didSet{
            if self.isHidden {
                self.contentView.frame = self.makeHiddenFrame()
            }
            else{
                self.contentView.frame = self.makeShownFrame()
            }
            self.addedContentView?.frame = self.contentView.bounds
        }
    }
    
    convenience init(){
        self.init(frame: UIScreen.main.bounds)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func initViews(){
        self.isHidden = true
        
        tapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapAction(_:)))
        self.overlayView.frame = self.bounds
        self.overlayView.addGestureRecognizer(tapRecognizer!)
        self.overlayView.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        
        self.addSubview(self.overlayView)
        self.overlayView.alpha = 0
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.frame = self.makeHiddenFrame()
        self.contentView.autoresizesSubviews = true
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(self.contentView)
    }
    
    @objc private func tapAction(_ gesture:UITapGestureRecognizer){
        if gesture.state == .ended {
            hide()
        }
    }
    
    private func makeHiddenFrame()->CGRect{
        return CGRect.init(x: -self.menuWidth, y: 0, width: self.menuWidth, height: UIScreen.main.bounds.height)
    }
    
    private func makeShownFrame()->CGRect{
        return CGRect.init(x: 0, y: 0, width: self.menuWidth, height: UIScreen.main.bounds.height)
    }
    
    func addSelfToRoot(){
        UIApplication.shared.delegate!.window!!.addSubview(self)
    }
    
    func setContentView(_ view:UIView){
        self.addedContentView?.removeFromSuperview()
        self.addedContentView = view
        self.contentView.addSubview(view)
        view.frame = self.contentView.bounds
    }
    
    func show(){
        if self.isHidden {
            self.isHidden = false
            UIView.animate(withDuration: 0.275) {[unowned self] in
                self.contentView.frame = self.makeShownFrame()
                self.overlayView.alpha = 1.0
            }
        }
    }
    
    func hide(){
        if !self.isHidden {

            UIView.animate(withDuration: 0.275, animations: {[unowned self] in
                self.contentView.frame = self.makeHiddenFrame()
                self.overlayView.alpha = 0
                
            }) { (finished) in
                self.isHidden = true
            }
        }
    }
}
