//
// Created by Zach Wang on 2019-02-08.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

class SVItemCell :UICollectionViewCell{

    static let textFont:CGFloat = 14

    private var _contentLabel:UILabel?
    private var normalFontSize:CGFloat{
        return SVItemCell.textFont
    }
    private let normalTextColor = UIColor.darkText

    private let rowNumberFontSize:CGFloat = 10
    private let rowNumberTextColor = UIColor.lightGray

    static let margin:CGFloat = 5
    private var margin:CGFloat{
        return SVItemCell.margin
    }
    private let borderWidth:CGFloat = 0.5

    let rightBorder = UIView()
    private let bottomBorder = UIView()

    var contentLabel:UILabel {
        if _contentLabel == nil{

            //先添加bgView到后面
            self.addSubview(self.bgView)

            _contentLabel = UILabel()

            self.addSubview(_contentLabel!)

            self.rightBorder.isHidden = true
            self.rightBorder.backgroundColor = UIColor.lightGray
            self.addSubview(self.rightBorder)

            self.bottomBorder.isHidden = true
            self.bottomBorder.backgroundColor = UIColor.lightGray
            self.addSubview(self.bottomBorder)
        }
        return _contentLabel!
    }

    let bgView = UIView()

    private var _style:SVItemStyle = .normal

    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentLabel.frame = CGRect.init(x: margin, y: 0, width: self.bounds.width - 2*margin, height: self.bounds.height)
        self.bottomBorder.frame = CGRect.init(x: 0, y: self.bounds.height - borderWidth, width: self.bounds.width, height: borderWidth)
        self.bgView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width - 1, height: self.bounds.height)
    }

    func setStyle(style:SVItemStyle){
        switch style {
            case .normal:
                self.contentLabel.font = UIFont.systemFont(ofSize: normalFontSize)
                self.contentLabel.textColor = normalTextColor
                self.contentLabel.textAlignment = .left
                self.backgroundColor = UIColor.white
                self.rightBorder.isHidden = true
                self.bottomBorder.isHidden = true
                break
            case .firstRow:
                self.contentLabel.font = UIFont.boldSystemFont(ofSize: normalFontSize)
                self.contentLabel.textColor = normalTextColor
                self.backgroundColor = UIColor.white
                self.contentLabel.textAlignment = .center
                self.rightBorder.isHidden = false
                self.bottomBorder.isHidden = false
                self.rightBorder.frame = CGRect.init(x: self.bounds.width - 2, y: margin, width: borderWidth, height: self.bounds.height - 2*margin)
                break
            case .firstColumn:
                self.contentLabel.font = UIFont.systemFont(ofSize: rowNumberFontSize)
                self.contentLabel.textColor = rowNumberTextColor
                self.backgroundColor = UIColor.init(white: 0.95, alpha: 1)
                self.contentLabel.textAlignment = .right
                self.rightBorder.isHidden = false
                self.bottomBorder.isHidden = true
                self.rightBorder.frame = CGRect.init(x: self.bounds.width - 2, y: 0, width: borderWidth, height: self.bounds.height)
                break
        }
    }
}

enum SVItemStyle{
    case normal
    case firstColumn
    case firstRow
}

enum SVItemBorderType{
    case left
    case top
    case right
    case bottom
}