//
// Created by Zach Wang on 2019-04-16.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import Foundation

class KeywordModel {
    var title:String = ""
    var type:KeywordType = .keyword
    var sub:[KeywordModel] = []

    ///实际显示的内容， 有可能跟title一致， 也有可能是个snippet
    var value:String = ""
}

enum KeywordType:String {
    case snippet
    case keyword
    case table
    case view
    case column
    case function
    case procedure
}
