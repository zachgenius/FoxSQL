//
// Created by Zach Wang on 2019-02-12.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

class MTTabCell : UICollectionViewCell{

    var closeButton:UIButton = UIButton(type: .roundedRect)
    var label:UILabel = UILabel()
    var divider = UIView()

    weak var delegate:MTTabCellDelegate?

    var indexPath:IndexPath?

    var active = true {
        didSet {
            if active{
                self.closeButton.isEnabled = true
                self.closeButton.tintColor = UIColor.darkGray
                self.label.textColor = UIColor.black
                self.backgroundColor = UIColor.white
            }
            else {
                self.closeButton.isEnabled = false
                self.closeButton.tintColor = UIColor.lightGray
                self.label.textColor = UIColor.gray
                self.backgroundColor = UIColor.init(white: 0.9, alpha: 1)
            }
        }
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.init(white: 0.9, alpha: 1)

        closeButton.setImage(UIImage.init(named: "close"), for: .normal)
        closeButton.tintColor = UIColor.gray
        closeButton.imageView?.contentMode = .scaleAspectFit
        closeButton.imageEdgeInsets = UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        self.addSubview(closeButton)

        label.textColor = UIColor.black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        self.addSubview(label)

        divider.backgroundColor = UIColor.gray
        self.addSubview(divider)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let itemWidth = self.bounds.width
        let itemHeight = self.bounds.height
        let margin:CGFloat = 5

        let closeButtonWidth = max(0, min(30, itemWidth - margin))

        closeButton.frame = CGRect.init(x: margin, y: 0, width: closeButtonWidth, height: itemHeight)

        let labelWidth = max(0, itemWidth - margin*2 - closeButtonWidth)
        label.frame = CGRect.init(x: margin*2 + closeButtonWidth, y: 0, width: labelWidth, height: itemHeight)

        divider.frame = CGRect.init(x: itemWidth - 0.5, y: 0, width: 0.5, height: itemHeight)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc func closeAction(){
        self.delegate?.close(indexPath: self.indexPath)
    }
}

protocol MTTabCellDelegate:class{
     func close(indexPath:IndexPath?)
}
