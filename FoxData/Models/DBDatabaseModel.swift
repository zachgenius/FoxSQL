//
// 库模型. 几个列表如果为空则为下载中. 如果为空数组则为无数据
// Created by Zach Wang on 2019-01-23.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import Foundation

class DBDatabaseModel {
    var type:DBType = .MySQL

    var name:String = ""

    var serverName:String = ""

    var tables: [String:[String]]?

    var views:[String:[String]]?

    var procedures: [String:[String]]?

    var functions: [String:[String]]?
    
    var isSample = false
}
