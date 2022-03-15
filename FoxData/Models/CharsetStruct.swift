//
// Created by Zach Wang on 2019-04-10.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import Foundation

struct CharsetStruct : Codable{
    var charset:[String]
    var collation:[String:[String]]
    var engine:[String]

}