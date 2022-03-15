//
// Created by Zach Wang on 2019-01-15.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit
import UIColor_Hex_Swift

class DBTypeCollectionView : UIView {

    var collectionView: UICollectionView? = nil
    lazy var panelLayout = UICollectionViewFlowLayout()
//    lazy var titleLabel = UILabel()

    func initViews(){

        self.backgroundColor = UIColor("#FFF5EB")

//        titleLabel.text = "New Connection"
//        titleLabel.textAlignment = .center
//        self.addSubview(titleLabel)

        panelLayout.itemSize = CGSize(width: 150, height: 150)
        panelLayout.minimumInteritemSpacing = 10
        panelLayout.minimumLineSpacing = 10

        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: panelLayout)
        collectionView!.showsHorizontalScrollIndicator = false
        collectionView!.showsVerticalScrollIndicator = false
        collectionView!.bounces = false
        collectionView!.register(DBPanelItemView.self, forCellWithReuseIdentifier: "DBType")
        collectionView?.backgroundColor = self.backgroundColor
        self.addSubview(collectionView!)

    }

    override func layoutSubviews() {
        super.layoutSubviews()
        var topOffset = 0 as CGFloat
        if #available(iOS 11, *) {
            topOffset = self.safeAreaInsets.top
        }

//        titleLabel.frame = CGRect(x: self.frame.origin.x, y: CGFloat(topOffset), width: self.frame.width, height: 20)
        collectionView?.frame = CGRect(x: self.frame.origin.x, y: CGFloat(topOffset + 10), width: self.frame.width, height: self.frame.height -  CGFloat(topOffset + 20))
    }
}
