//
//  DBPanelItemView.swift
//  FoxData
//  新建数据库的时候的item, 上面Logo下面名称
//  Created by Zach Wang on 2019/1/13.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

class DBPanelItemView: UICollectionViewCell {
    
    lazy var imageView = UIImageView()
    lazy var label = UILabel()

    var hasInit = false
    
    func initViews(type:DBType){
        switch type {
        case .MySQL:
            imageView.image = UIImage.init(named: "icon_mysql_add")
            label.text = "MySQL"
            break
            
        case .SQLServer:
            
            break
        case .PostgreSQL:
            imageView.image = UIImage.init(named: "icon_postgres")
            label.text = "PostgreSQL"
            break
            
        case .MongoDB:
            imageView.image = UIImage.init(named: "icon_mongodb")
            label.text = "MongoDB"
            break
        case .Cassandra:
            imageView.image = UIImage.init(named: "icon_cassandra")
            label.text = "Cassandra"
            break
        case .Redis:
            imageView.image = UIImage.init(named: "icon_redis")
            label.text = "Redis"
            break
        case .Memcached:
            imageView.image = UIImage.init(named: "icon_memcached")
            label.text = "Memcached"
            break

        }



        if !hasInit {
            self.addSubview(imageView)
            self.addSubview(label)
        }

        imageView.snp.makeConstraints { maker in
            maker.width.height.equalTo(100)
            maker.top.equalTo(10)
            maker.centerX.equalToSuperview()
        }

        label.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(imageView.snp.bottom).offset(10)
        }
    }

}
