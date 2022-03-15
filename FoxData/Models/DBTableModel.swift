//
// table
// Created by Zach Wang on 2019-01-23.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import Foundation

class DBTableModel {
    var name:String?
    var columns:[DBTableColumnPropModel]?
    var indexes:[DBTableIndexPropModel]?
    var triggers:[DBTableTriggerModel]?
}
