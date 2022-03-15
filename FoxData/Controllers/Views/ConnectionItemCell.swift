//  新建连接列表当中的cell
//  ConnectionItemCell.swift
//  FoxData
//
//  Created by Zach Wang on 2019/3/5.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit

class ConnectionItemCell: UITableViewCell {

    let menuButton:UIButton = UIButton.init(type: .roundedRect)
    
    var indexPath:IndexPath?
    weak var delegate:ConnectionItemCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initViews(){
        menuButton.setImage(UIImage.init(named: "setting"), for: .normal)
        menuButton.imageView?.contentMode = .scaleAspectFit
        menuButton.imageEdgeInsets = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
        menuButton.addTarget(self, action: #selector(menuClick), for: .touchUpInside)
        menuButton.imageView?.backgroundColor = UIColor.white
        menuButton.isHidden = true
        menuButton.tintColor = UIColor.init("#1296db")
        self.accessoryView = menuButton
    }
    
    @objc private func menuClick(){
        self.delegate?.onMenuClick(self.menuButton, self.indexPath!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let imgWidth:CGFloat = 40;
        menuButton.frame = CGRect.init(x: self.bounds.width - imgWidth - 10, y: 0, width: imgWidth - 5, height: self.bounds.height)
    }
}

protocol ConnectionItemCellDelegate: class{
    func onMenuClick(_ anchorView:UIView, _ indexPath:IndexPath)
}
