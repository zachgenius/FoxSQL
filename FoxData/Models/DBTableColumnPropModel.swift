//
// Created by Zach Wang on 2019-02-27.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import Foundation

class DBTableColumnPropModel {
    var name:String = ""
    var length:Int32 = 0
    var nullable:Bool = false
    var primary:Bool = false
    var autoIncrement:Bool = false
    var defaultValue:String?
    var type:DBColumnType = .INT
    var comment:String?
}

enum DBColumnType:String {
    case DECIMAL
    case TINY
    case SHORT
    case LONG
    case FLOAT
    case DOUBLE
    case NULL
    case TIMESTAMP
    case LONGLONG
    case INT = "INT"
    case DATE
    case TIME
    case DATETIME
    case YEAR
    case NEWDATE
    case CHAR
    case VARCHAR
    case BIT
    case JSON
    case NEWDECIMAL
    case ENUM
    case SET
    case TINYBLOB
    case MEDIUMBLOB
    case LONGBLOB
    case VARSTRING = "VAR STRING"
    case STRING
    case GEOMETRY
    case TEXT

    static func getMySQLTypes() -> [DBColumnType]{
        return [
            CHAR,
            VARCHAR,
            TEXT,
            DECIMAL,
            TINY,
            SHORT,
            INT,
            LONG,
            LONGLONG,
            FLOAT,
            DOUBLE,
            TIMESTAMP,
            DATE,
            TIME,
            DATETIME,
            YEAR,
            BIT,
            JSON,
            ENUM,
            SET,
            TINYBLOB,
            MEDIUMBLOB,
            LONGBLOB,
            GEOMETRY
        ]
    }
}
