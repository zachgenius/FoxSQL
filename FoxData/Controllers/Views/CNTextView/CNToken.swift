//
// Created by Zach Wang on 2019-02-11.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import Foundation

class CNToken {
    var name:String
    var expression:String
    var attributes:[NSAttributedString.Key:Any]

    init(name:String, expression:String, attributes:[NSAttributedString.Key:Any]){
        self.name = name
        self.expression = expression
        self.attributes = attributes
    }

}
