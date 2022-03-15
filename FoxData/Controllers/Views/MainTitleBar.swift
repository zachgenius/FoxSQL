//
//  MainTitleBar.swift
//  FoxData
//
//  Created by Zach Wang on 2019/1/13.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

class MainTitleBar: UIButton {

    private let dbLabel:UILabel = UILabel()
    private let serverLabel:UILabel = UILabel()

    func initViews(){

        dbLabel.font = UIFont.boldSystemFont(ofSize: 18)
        dbLabel.textAlignment = .center
        serverLabel.font = UIFont.systemFont(ofSize: 16)
        serverLabel.textAlignment = .center
        self.addSubview(dbLabel)
        self.addSubview(serverLabel)

        dbLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
        }

        serverLabel.snp.makeConstraints { maker in
            maker.bottom.equalTo(dbLabel)
            maker.left.equalTo(dbLabel.snp.right).offset(5)
        }
        self.clipsToBounds = false
    }

    func setData(db:String, server:String){
        dbLabel.text = db
        serverLabel.text = "(\(server))"
    }

}
