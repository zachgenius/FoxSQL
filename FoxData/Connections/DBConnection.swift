//
// 数据库连接基本协议
// Created by Zach Wang on 2019-01-23.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import Foundation

protocol DBConnection:class {
    var delegate:DBConnectionCallBackDelegate?{get set }
    var connection:DBConnectionModel{ get }
    var localListeningPort:Int{get set}

    static func checkAuth(_ server:DBConnectionModel, _ callback: @escaping (_ status:Int, _ info:String) -> Void)
    
    func connect()
    
    func getDatabases()
    func getTables(dbName:String)
    func getViews(dbName:String)
    func getProcedures(dbName:String)
    func getFunctions(dbName:String)
    func query(sql:String, db:String)
    func cacheDBKeywords(dbName:String)
    func getCreateValue(type:ShowCreateType, db:String, name:String)
    func close()

    func addQuery(sql:String, db:String, complete:DBConnectionQueryCompleteBlock?)
    func showScheme(table:String, db:String, complete:DBConnectionQueryCompleteBlock?)
}

protocol DBConnectionCallBackDelegate: class{

    func onServerConnected()

    func onFetchDatabases(results:[String]?, info:String?)

    /// result: [section:[tableNames]]
    func onFetchTables(results:[String:[String]]?, info:String?)

    /// result: [section:[title:value]]
    func onFetchViews(results:[String:[String]]?, info:String?)

    /// result: [section:[title]]
    func onFetchProcedures(results:[String:[String]]?, info:String?)
    func onFetchFunctions(results:[String:[String]]?, info:String?)

    /// 获取各种Create声明内容
    func onFetchCreateValue(result:String?, type:ShowCreateType, name:String, db:String, info:String?)

    /// result: [[resultColumnItem]]
    func onQueryResult(result:[[DBQueryResultItemModel]]?, sql:String, info:String?)

    func onConnectionError(err:DBConnectionError, info:String?)
}

enum DBConnectionError : Int {
    case connectionFailed = 1
    case sshConnectionFailed

    case other = 999
}

typealias DBConnectionQueryCompleteBlock = (_ result:[[DBQueryResultItemModel]]?, _ sql:String, _ db:String, _ info:String?, _ statusCode:Int32) -> Void
typealias DBConnectionQueryFieldsCompleteBlock = (_ result:[DBTableColumnPropModel]?, _ sql:String, _ db:String, _ info:String?, _ statusCode:Int32) -> Void
typealias DBConnectionQueryIndexesCompleteBlock = (_ result:[DBTableIndexPropModel]?, _ sql:String, _ db:String, _ info:String?, _ statusCode:Int32) -> Void
typealias DBConnectionQueryTriggersCompleteBlock = (_ result:[DBTableTriggerModel]?, _ sql:String, _ db:String, _ info:String?, _ statusCode:Int32) -> Void
