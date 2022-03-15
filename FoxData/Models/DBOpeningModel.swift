//
// 连接中的数据库
// Created by Zach Wang on 2019-01-23.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import Foundation

class DBOpeningModel {
    var dbItem: DBConnectionModel?
    let databases: Array<DBDatabaseModel> = Array()
    var connection: DBConnection?
}
