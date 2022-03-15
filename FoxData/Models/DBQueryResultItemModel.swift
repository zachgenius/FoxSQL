// 结果model
// Created by Zach Wang on 2019-03-02.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import Foundation

class DBQueryResultItemModel {
    var text:String?
    var type:DBQueryResultItemType = .text
    var isPrimary = false
    var table:String? // table 为空则该结果不可被修改和删除
}
enum DBQueryResultItemType {
    case text
    case blob
    case title
}