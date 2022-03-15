//
// 关键字管理器
// Created by Zach Wang on 2019-01-24.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

class KeywordManager {
    private static let _sharedManager = KeywordManager()

    private init(){

    }

    class func get()->KeywordManager {
        return _sharedManager
    }

    var keywords:[KeywordModel] = []

    func clearKeywords(){
        keywords.removeAll()
        loadBasicKeywords()
    }

    private func loadBasicKeywords(){
        //SELECT
        keywords.append(makeKeyword("SELECT", "SELECT", .keyword))
        keywords.append(makeKeyword("SELECT", "SELECT * FROM $table$ WHERE $cond$ LIMIT 100;", .snippet))

        //UPDATE
        keywords.append(makeKeyword("UPDATE", "UPDATE", .keyword))
        keywords.append(makeKeyword("UPDATE", "UPDATE $table$ SET $column$=$value WHERE $cond$;", .snippet))

        //INSERT
        keywords.append(makeKeyword("INSERT", "INSERT", .keyword))
        keywords.append(makeKeyword("INSERT", "INSERT INTO $table$ ($column$) VALUES ($value$);", .snippet))

        //DELETE
        keywords.append(makeKeyword("DELETE", "DELETE", .keyword))
        keywords.append(makeKeyword("DELETE", "DELETE FROM $table$ WHERE $cond$;", .snippet))
        
        keywords.append(makeKeyword("ALTER", "ALTER", .keyword))
        keywords.append(makeKeyword("CREATE", "CREATE", .keyword))
        
        keywords.append(makeKeyword("DROP", "DROP", .keyword))
        keywords.append(makeKeyword("DROP", "DROP TABLE $table$;", .snippet))
        
        keywords.append(makeKeyword("RENAME", "RENAME", .keyword))
        keywords.append(makeKeyword("RENAME", "RENAME TABLE $old_table$ TO $new_table$;", .snippet))
        
        keywords.append(makeKeyword("TRUNCATE", "TRUNCATE", .keyword))
        keywords.append(makeKeyword("TRUNCATE", "TRUNCATE TABLE $table$;", .snippet))
    }

    private func makeKeyword(_ title:String, _ value:String, _ type:KeywordType) -> KeywordModel{
        let key = KeywordModel()
        key.title = title
        key.value = value
        key.type = type
        return key
    }

}
