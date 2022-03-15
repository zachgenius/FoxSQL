//
//  DBConnectionModel.swift
//  连接器 存入本地数据库
//
//  Created by Zach Wang on 2019/1/13.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit

@objc class DBConnectionModel: NSObject {

    @objc var type = DBType.MySQL

    //id设为uuid
    @objc var id:String = ""
    @objc var createTime:Int = 0

    @objc var alias:String = ""
    @objc var host:String = ""
    @objc var port:UInt32 = 3306
    @objc var username:String = ""
    @objc var password:String = ""
    @objc var db:String = ""
    @objc var charset:String = "utf8md4"

    @objc var isSSH = false
    @objc var sshHost = ""
    @objc var sshUser = ""
    @objc var sshPort:Int = 22
    @objc var sshPassword = ""
    @objc var sshIsKey = false // false 用password, 反之用pubkey
    @objc var sshPubKey = ""
    @objc var sshPrivKey = ""
    @objc var sshPrivPasswordPhrase = ""// 私钥密码
    
    var isSample = false
    
    override init() {
        
    }
    
    init(type:DBType) {
        self.type = type
        switch type {
        case .MySQL:
            port = 3306
            break
        case .PostgreSQL:
            port = 5432
            break
        default:
            break
        }
    }
}

@objc enum DBType : Int {
    
    //下面是结构化数据库
    case MySQL = 0
    case PostgreSQL
    case SQLServer
    
    //下面的都是NoSQL
    case MongoDB
    case Cassandra
    
    //下面是内存数据库
    case Redis
    case Memcached
}
