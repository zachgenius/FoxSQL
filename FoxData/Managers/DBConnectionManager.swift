//
// 数据库连接管理工具. 只管理连接数据, 不管理界面.
// Created by Zach Wang on 2019-01-22.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

class DBConnectionManager{


    ///只用于 PadMain或者PhMain
    weak var delegate:DBConnectionManagerDelegate?


    private(set) var dbConnection:DBConnection?
    private(set) var databases:[DBDatabaseModel]?
    private(set) var server:DBConnectionModel?

    func connectServer(_ server:DBConnectionModel){
        if server.type == DBType.MySQL {
            self.dbConnection = DBConnectionMySQL(server)
        }

        dbConnection?.delegate = self
        databases = nil
        self.server = server
        
        dbConnection?.connect()
    }

    func getDatabases(){
        dbConnection?.getDatabases()
    }
    func getTables(dbName:String){
        dbConnection?.getTables(dbName: dbName)
    }
    func getViews(dbName:String){
        dbConnection?.getViews(dbName: dbName)
    }
    func getProcedures(dbName:String){
        dbConnection?.getProcedures(dbName: dbName)
    }

    func getFunctions(dbName:String){
        dbConnection?.getFunctions(dbName: dbName)
    }
    func query(sql:String, db:String){
        dbConnection?.query(sql: sql, db: db)
    }

    func switchDB(dbName:String){
        dbConnection?.close()

        let server = dbConnection!.connection
        server.db = dbName
        connectServer(server)
    }

    func getCreateValue(type:ShowCreateType, db:String, name:String){
        dbConnection?.getCreateValue(type: type, db: db, name: name)
    }

    func addQuery(sql:String, db:String, complete:DBConnectionQueryCompleteBlock?){
        dbConnection?.addQuery(sql: sql, db: db, complete: complete)
    }

    func showScheme(table:String, db:String, complete:DBConnectionQueryCompleteBlock?){
        dbConnection?.showScheme(table: table, db: db, complete: complete)
    }
}

extension DBConnectionManager:DBConnectionCallBackDelegate{
    func onFetchDatabases(results: [String]?, info: String?) {
        self.delegate?.onFetchDatabases(results: results, info: info)
    }

    func onFetchTables(results:[String:[String]]?, info:String?){
        self.delegate?.onFetchTables(results: results, info: info)
    }

    func onFetchProcedures(results: [String: [String]]?, info: String?) {
        self.delegate?.onFetchProcedures(results: results, info: info)
    }

    func onFetchViews(results: [String: [String]]?, info: String?) {
        self.delegate?.onFetchViews(results: results, info: info)
    }

    func onFetchFunctions(results: [String: [String]]?, info: String?) {
        self.delegate?.onFetchFunctions(results: results, info: info)
    }

    func onQueryResult(result:[[DBQueryResultItemModel]]?, sql:String, info:String?){
        self.delegate?.onQueryResult(result: result, sql:sql, info: info)
    }

    func onFetchCreateValue(result: String?, type: ShowCreateType, name: String, db: String, info: String?) {
        self.delegate?.onFetchCreateValue(result: result, type: type, name: name, db: db, info: info)
    }

    func onConnectionError(err: DBConnectionError, info: String?) {
        self.delegate?.onConnectionError(err: err, info: info)
    }

    func onServerConnected() {
        self.delegate?.onServerConnected()
        
        //直接缓存表结构
        self.dbConnection?.cacheDBKeywords(dbName: self.server!.db)
    }
}


protocol DBConnectionManagerDelegate : DBConnectionCallBackDelegate{

}
