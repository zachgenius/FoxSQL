//
// 单线程
// Created by Zach Wang on 2019-02-17.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import Foundation

class DBConnectionMySQL : DBConnection {
    
    weak var delegate: DBConnectionCallBackDelegate? = nil
    private(set) var connection: DBConnectionModel

    private let queryQueue = DispatchQueue(label: "mysqlConn", qos: .background)

    private var mysql:UnsafeMutablePointer<MYSQL>?

    private var sshTunnel:SSHTunnel?

    ///实际连接的地址， 有可能是远程， 有可能是本机转发
    private var realConnectHost = ""
    private var realConnectPort = 3306

    var localListeningPort = 10100

    init(_ connection:DBConnectionModel){
        self.connection = connection
        if connection.isSSH {
            sshTunnel = SSHTunnel()
            sshTunnel?.delegate = self
            sshTunnel?.sshHost = connection.sshHost
            sshTunnel?.sshUsername = connection.sshUser
            sshTunnel?.sshPort = Int32(connection.sshPort)
            sshTunnel?.sshIsKey = connection.sshIsKey
            sshTunnel?.sshPubKey = connection.sshPubKey
            sshTunnel?.sshPrivKey = connection.sshPrivKey
            sshTunnel?.sshPrivKeyPassword = connection.sshPrivPasswordPhrase
            sshTunnel?.sshPassword = connection.sshPassword
            sshTunnel?.remoteDestHost = connection.host
            sshTunnel?.remoteDestPort = Int32(connection.port)
            sshTunnel?.localListeningPort = Int32(localListeningPort)
        }
        else {
            realConnectHost = connection.host
            
            //本机内不启动mysqld, 这时是虚拟机内, 连接到主机
            if realConnectHost.lowercased() == "localhost"{
                realConnectHost = "127.0.0.1"
            }
            
            realConnectPort = Int(connection.port)
        }
        
    }
    
    static func checkAuth(_ server: DBConnectionModel, _ callback: @escaping (Int, String) -> Void) {
        if server.isSSH {
            let ssh = SSHTunnel()
            
            ssh.sshHost = server.sshHost
            ssh.sshUsername = server.sshUser
            ssh.sshPort = Int32(server.sshPort)
            ssh.sshIsKey = server.sshIsKey
            ssh.sshPubKey = server.sshPubKey
            ssh.sshPrivKey = server.sshPrivKey
            ssh.sshPrivKeyPassword = server.sshPrivPasswordPhrase
            ssh.sshPassword = server.sshPassword
            ssh.remoteDestHost = server.host
            ssh.remoteDestPort = Int32(server.port)
            ssh.connect(success: { (localhost, localport) in
                self.testMysqlAuth(server, localhost, UInt32(localport), callback)
                
            }) { (errCode, msg) in
                __dispatch_async(.main) {() -> Void in
                    callback(-1, "SSH Authentication Failed")
                }
            }
            
            ssh.connect()
        }
        else{
            var host = server.host
            if host.lowercased() == "localhost" {
                host = "127.0.0.1"
            }
            let port = server.port
            self.testMysqlAuth(server, host, port, callback)
        }
    }

    private static func testMysqlAuth(_ server:DBConnectionModel, _ host:String, _ port:UInt32, _ callback: @escaping (Int, String) -> Void){
        DispatchQueue.init(label: "auth").async {
            let mysql = mysql_init(nil)
            var reconnect:my_bool = 1
            mysql_options(mysql, MYSQL_OPT_RECONNECT, &reconnect)

            let conn = mysql_real_connect(mysql,
                    host,
                    server.username,
                    server.password,
                    server.db,
                    port,
                    nil,
                    0)

            if conn != nil {
                __dispatch_async(.main) { () -> Void in
                    callback(0, "Success")
                }
            }
            else {
                __dispatch_async(.main) {() -> Void in
                    callback(-1, "MySQL Authentication Failed")
                }

            }

            mysql_close(mysql)
        }
    }
    
    func connect(){
        if connection.isSSH {
            sshTunnel?.close()
            sshTunnel?.connect()
        }
        else{
            getTables(dbName: connection.db)
            getViews(dbName: connection.db)
            getDatabases()
            getProcedures(dbName: connection.db)
            getFunctions(dbName: connection.db)
        }
    }

    /// 同步方法 
    private func checkAndConnect(type:Int){

        if connection.isSSH && !sshTunnel!.isConnected {
            sshTunnel?.connect()
            return
        }

        if mysql == nil {
            mysql = mysql_init(nil)
            var reconnect:my_bool = 1
            mysql_options(mysql, MYSQL_OPT_RECONNECT, &reconnect)
        
            let conn = mysql_real_connect(mysql,
                    realConnectHost,
                    connection.username,
                    connection.password,
                    connection.db,
                    UInt32(realConnectPort),
                    nil,
                    0)

            if conn != nil {
                mysql_set_character_set(conn, connection.charset)
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onServerConnected()
                }
            }
            else {
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onConnectionError(err: .connectionFailed, info: "Connection Failed")
                }
                
            }
        }

    }

    func getDatabases(){
        queryQueue.async {  [unowned self] () -> Void in
            self.checkAndConnect(type: 1)
            guard let mysql = self.mysql else {
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchDatabases(results: nil, info: "Lost Connection. Please try again later")
                }

                return
            }

            let sql = "SHOW DATABASES;"
            let status = mysql_real_query(mysql, sql, UInt(sql.count))
            var tableNames:[String] = []
            if status == 0 {
                let result = mysql_store_result(mysql)
                if result != nil {
                    var row:MYSQL_ROW?
                    row = mysql_fetch_row(result)
                    while row != nil{
                        let charData = row?[0]
                        let stringData = String.init(cString: charData!, encoding: .utf8)
                        tableNames.append(stringData!)
                        row = mysql_fetch_row(result)
                    }

                    mysql_free_result(result)

                }

                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchDatabases(results: tableNames, info: nil)
                }
            }
            else {
                let msgPointer = mysql_error(mysql)
                let msg:String?
                if msgPointer == nil{
                    msg = ""
                }
                else {
                    msg = String.init(cString: msgPointer!, encoding: .utf8)
                }
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchDatabases(results: nil, info: msg)
                }
            }
        }
    }
    func getTables(dbName:String){
        if dbName.isEmpty{
            self.delegate?.onFetchTables(results: ["Failed" : []], info: nil)
            return
        }
        queryQueue.async {  [unowned self] () -> Void in
            self.checkAndConnect(type: 1)
            guard let mysql = self.mysql else {
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchTables(results: nil, info: "Lost Connection. Please try again later")
                }
                return
            }

            let sql = "SHOW FULL TABLES IN " + dbName + " WHERE TABLE_TYPE NOT LIKE 'VIEW';"
            let status = mysql_real_query(mysql, sql, UInt(sql.count))
            var tableNames:[String] = []
            if status == 0 {
                let result = mysql_store_result(mysql)
                if result != nil {
                    var row:MYSQL_ROW?
                    row = mysql_fetch_row(result)
                    while row != nil{
                        let charData = row?[0]
                        let stringData = String.init(cString: charData!, encoding: .utf8)
                        tableNames.append(stringData!)
                        row = mysql_fetch_row(result)
                    }

                    mysql_free_result(result)

                }

                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchTables(results: ["All":tableNames], info: nil)
                }
            }
            else {
                let msgPointer = mysql_error(mysql)
                let msg:String?
                if msgPointer == nil{
                    msg = ""
                }
                else {
                    msg = String.init(cString: msgPointer!, encoding: .utf8)
                }
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchTables(results: nil, info: msg)
                }
            }

        }

    }
    func getViews(dbName:String){
        if dbName.isEmpty{
            self.delegate?.onFetchViews(results: ["Failed" : []], info: nil)
            return
        }
        queryQueue.async {  [unowned self] () -> Void in
            self.checkAndConnect(type: 1)
            guard let mysql = self.mysql else {
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchViews(results: nil, info: "Lost Connection. Please try again later")
                }
                return
            }

            let sql = "SHOW FULL TABLES IN " + dbName + " WHERE TABLE_TYPE LIKE 'VIEW';"
            let status = mysql_real_query(mysql, sql, UInt(sql.count))
            var tableNames:[String] = []
            if status == 0 {
                let result = mysql_store_result(mysql)
                if result != nil {
                    var row:MYSQL_ROW?
                    row = mysql_fetch_row(result)
                    while row != nil{
                        let charData = row?[0]
                        let stringData = String.init(cString: charData!, encoding: .utf8)
                        tableNames.append(stringData!)
                        row = mysql_fetch_row(result)
                    }

                    mysql_free_result(result)

                }

                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchViews(results: ["All":tableNames], info: nil)
                }
            }
            else {
                let msgPointer = mysql_error(mysql)
                let msg:String?
                if msgPointer == nil{
                    msg = ""
                }
                else {
                    msg = String.init(cString: msgPointer!, encoding: .utf8)
                }
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchViews(results: nil, info: msg)
                }
            }
        }

    }
    func getProcedures(dbName:String){
        if dbName.isEmpty{
            self.delegate?.onFetchProcedures(results: ["Failed" : []], info: nil)
            return
        }
        queryQueue.async {  [unowned self] () -> Void in
            self.checkAndConnect(type: 1)
            guard let mysql = self.mysql else {
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchProcedures(results: nil, info: "Lost Connection. Please try again later")
                }
                return
            }


            let sql = "SHOW PROCEDURE STATUS WHERE db = '" + dbName + "';"
            let status = mysql_real_query(mysql, sql, UInt(sql.count))
            var tableNames:[String] = []
            if status == 0 {
                let result = mysql_store_result(mysql)
                if result != nil {
                    var row:MYSQL_ROW?
                    row = mysql_fetch_row(result)
                    while row != nil{
                        let charData = row?[1]
                        let stringData = String.init(cString: charData!, encoding: .utf8)
                        tableNames.append(stringData!)
                        row = mysql_fetch_row(result)
                    }

                    mysql_free_result(result)

                }

                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchProcedures(results: ["All" : tableNames], info: nil)
                }
            }
            else {
                let msgPointer = mysql_error(mysql)
                let msg:String?
                if msgPointer == nil{
                    msg = ""
                }
                else {
                    msg = String.init(cString: msgPointer!, encoding: .utf8)
                }
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchProcedures(results: nil, info: msg)
                }
            }
        }

    }

    func getFunctions(dbName:String){
        if dbName.isEmpty{
            self.delegate?.onFetchFunctions(results: ["Failed" : []], info: nil)
            return
        }
        queryQueue.async {  [unowned self] () -> Void in
            self.checkAndConnect(type: 1)
            guard let mysql = self.mysql else {
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchFunctions(results: nil, info: "Lost Connection. Please try again later")
                }
                return
            }


            let sql = "SHOW FUNCTION STATUS WHERE db = '" + dbName + "';"
            let status = mysql_real_query(mysql, sql, UInt(sql.count))
            var tableNames:[String] = []
            if status == 0 {
                let result = mysql_store_result(mysql)
                if result != nil {
                    var row:MYSQL_ROW?
                    row = mysql_fetch_row(result)
                    while row != nil{
                        let charData = row?[1]
                        let stringData = String.init(cString: charData!, encoding: .utf8)
                        tableNames.append(stringData!)
                        row = mysql_fetch_row(result)
                    }

                    mysql_free_result(result)

                }

                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchFunctions(results: ["All" : tableNames], info: nil)
                }
            }
            else {
                let msgPointer = mysql_error(mysql)
                let msg:String?
                if msgPointer == nil{
                    msg = ""
                }
                else {
                    msg = String.init(cString: msgPointer!, encoding: .utf8)
                }
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchFunctions(results: nil, info: msg)
                }
            }
        }

    }

    func query(sql:String, db:String = ""){
        self.addQuery(sql: sql, db: db) {  [unowned self] resultItemModels, sql, db, info, status in
            self.delegate?.onQueryResult(result: resultItemModels, sql:sql, info: info)
        }
    }

    func getCreateValue(type: ShowCreateType, db: String, name: String) {
        queryQueue.async {  [unowned self] () -> Void in
            self.checkAndConnect(type: 0)
            guard let mysql = self.mysql else {
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchCreateValue(result: nil, type: type, name: name, db: db, info: "Lost Connection. Please try again later")
                }
                return
            }

            let sql:String
            switch type{
            case .function:
                sql = "SHOW CREATE FUNCTION " + name + ";"
                break
            case .procedure:
                sql = "SHOW CREATE PROCEDURE " + name + ";"
                break
            case .table:
                sql = "SHOW CREATE TABLE " + name + ";"
                break
            case .view:
                sql = "SHOW CREATE VIEW " + name + ";"
                break
            }

            let status = mysql_real_query(mysql, sql, UInt(sql.count))
            var tableNames:[String] = []
            if status == 0 {
                let result = mysql_store_result(mysql)
                if result != nil {
                    var row:MYSQL_ROW?
                    row = mysql_fetch_row(result)
                    while row != nil{
                        let index:Int
                        if type == .table || type == .view{
                            index = 1
                        }
                        else {
                            index = 2
                        }
                        let charData = row?[index]
                        let stringData = String.init(cString: charData!, encoding: .utf8)
                        tableNames.append(stringData!)
                        row = mysql_fetch_row(result)
                    }

                    mysql_free_result(result)

                }

                __dispatch_async(.main) { [unowned self] () -> Void in
                    if tableNames.isEmpty{
                        self.delegate?.onFetchCreateValue(result: "", type:type, name: name, db: db, info: nil)
                    }
                    else{
                        self.delegate?.onFetchCreateValue(result: tableNames[0], type:type, name: name, db: db, info: nil)
                    }
                }
            }
            else {
                let msgPointer = mysql_error(mysql)
                let msg:String?
                if msgPointer == nil{
                    msg = ""
                }
                else {
                    msg = String.init(cString: msgPointer!, encoding: .utf8)
                }
                __dispatch_async(.main) { [unowned self] () -> Void in
                    self.delegate?.onFetchCreateValue(result: nil, type:type, name: name, db: db, info: msg)
                }
            }
        }
    }

    func cacheDBKeywords(dbName: String) {
        if dbName == "" {
            return
        }
        queryQueue.async {  [unowned self] () -> Void in
            self.checkAndConnect(type: 2)
            guard let mysql = self.mysql else {
                return
            }

            //获取所有表
            let sql = "SHOW FULL TABLES IN " + dbName + " WHERE TABLE_TYPE NOT LIKE 'VIEW';"
            let status = mysql_real_query(mysql, sql, UInt(sql.count))
            var tableNames:[String] = []
            if status == 0 {
                let result = mysql_store_result(mysql)
                if result != nil {
                    var row:MYSQL_ROW?
                    row = mysql_fetch_row(result)
                    while row != nil{
                        let charData = row?[0]
                        let stringData = String.init(cString: charData!, encoding: .utf8)
                        tableNames.append(stringData!)
                        row = mysql_fetch_row(result)
                    }
                    
                    mysql_free_result(result)
                    
                }
                
                //先将表存在keywords里
                for item in tableNames{
                    let key = KeywordModel.init()
                    key.title = item
                    key.value = item
                    key.type = .table
                    KeywordManager.get().keywords.append(key)
                }
                
                __dispatch_async(.main) { [unowned self] () -> Void in
                    if !tableNames.isEmpty {
                        self.cacheTable(tableNames)
                    }
                }
            }
            
        }
    }
    
    ///不断调用递归区获取表的结构
    private func cacheTable(_ tables:[String]){
        if tables.isEmpty {
            return
        }
        queryQueue.async { [unowned self] () -> Void in
            self.checkAndConnect(type: 0)
            guard let mysql = self.mysql else {
                return
            }
            
            let table = tables[0]
            let sql = "select * from \(table) limit 1"
            let status = mysql_real_query(mysql, sql, UInt(sql.count))
            if status == 0 {
                let result = mysql_store_result(mysql)
                if result != nil {
                    let fieldNum = mysql_num_fields(result)
                    let fields: UnsafeMutablePointer<MYSQL_FIELD>? = mysql_fetch_fields(result)
                    var titles: [String] = []
                    for index in (0...fieldNum - 1) {
                        let charData = fields?[Int(index)].name
                        let text:String
                        if charData != nil {
                            text = String.init(cString: charData!, encoding: .utf8) ?? ""
                        } else {
                            text = ""
                        }
                        
                        titles.append(text)
                    }
                    
                    let keywords = KeywordManager.get().keywords
                    
                    //寻找并存储fields
                    for item in keywords {
                        if item.title == table && item.type == .table{
                            
                            for field in titles {
                                let key = KeywordModel()
                                key.title = field
                                key.value = field
                                key.type = .column
                                item.sub.append(key)
                            }
                            
                            break
                        }
                    }
                    
                    mysql_free_result(result)
                    
                }
                
            }
            
            __dispatch_async(.main) {  [unowned self] () -> Void in
                var newTables:[String] = []
                newTables.append(contentsOf: tables)
                newTables.removeFirst()
                
                self.cacheTable(newTables)
            }
        }
    }

    func close() {
        if self.mysql != nil{
           mysql_close(self.mysql)
        }

        self.mysql = nil
        self.sshTunnel?.close()
    }

    func addQuery(sql: String, db: String, complete: DBConnectionQueryCompleteBlock?) {
        queryQueue.async {  [unowned self] () -> Void in
            self.checkAndConnect(type: 0)
            guard let mysql = self.mysql else {
                __dispatch_async(.main) { [unowned self] () -> Void in
                    complete?(nil, sql, db, "Lost Connection. Please try again later", -1)
                }
                return
            }

            let status = mysql_real_query(mysql, sql, UInt(sql.count))
            var resultData:[[DBQueryResultItemModel]] = []
            var info = ""
            if status == 0 {
                let result = mysql_store_result(mysql)
                if result != nil {
                    let fieldNum = mysql_num_fields(result)
                    let fields: UnsafeMutablePointer<MYSQL_FIELD>? = mysql_fetch_fields(result)
                    var titles: [DBQueryResultItemModel] = []
                    for index in (0...fieldNum - 1) {
                        let charData = fields?[Int(index)].name
                        let text:String
                        if charData != nil {
                            text = String.init(cString: charData!, encoding: .utf8) ?? ""
                        } else {
                            text = ""
                        }
                        let itemModel = DBQueryResultItemModel()
                        itemModel.type = .title
                        itemModel.text = text
                        titles.append(itemModel)
                    }
                    resultData.append(titles)
                    var row: MYSQL_ROW? = mysql_fetch_row(result)

                    while row != nil {
                        var data: [DBQueryResultItemModel] = []
                        for index in (0...fieldNum - 1) {
                            let charData = row?[Int(index)]
                            let field = fields![Int(index)]
                            let itemModel = DBQueryResultItemModel()

                            //是否是文件
                            if field.type == MYSQL_TYPE_BLOB {
                                if field.charsetnr == 63{
                                    itemModel.type = .blob
                                    itemModel.text = "FILE"
                                }
                                else{
                                    var text:String?
                                    if charData != nil {
                                        text = String.init(cString: charData!, encoding: .utf8)
                                    }
                                    
                                    itemModel.type = .text
                                    itemModel.text = text
                                }
                            }
                            else if field.type == MYSQL_TYPE_LONG_BLOB
                                || field.type == MYSQL_TYPE_MEDIUM_BLOB{

                                itemModel.type = .blob
                                itemModel.text = "FILE"
                            }
                            else {
                                var text:String?
                                if charData != nil {
                                    text = String.init(cString: charData!, encoding: .utf8)
                                }

                                itemModel.type = .text
                                itemModel.text = text
                            }

                            if MySQLBridge.isPrivateKey(field.flags){
                                itemModel.isPrimary = true
                            }

                            data.append(itemModel)
                        }

                        resultData.append(data)
                        row = mysql_fetch_row(result)
                    }

                    if resultData.count > 0 {
                        info = "\(resultData.count - 1) rows fetched"
                    }
                    else {
                        let rowsAffected = mysql_affected_rows(mysql)
                        if rowsAffected >= 0{
                            info = "\(rowsAffected) rows affected"
                        }
                        else {
                            let msgPointer = mysql_error(mysql)
                            if msgPointer == nil{
                                info = "Unknown error"
                            }
                            else {
                                info = String.init(cString: msgPointer!, encoding: .utf8) ?? "Unknown error"
                            }
                        }
                    }

                    mysql_free_result(result)

                }

                __dispatch_async(.main) {  [unowned self] () -> Void in
                    complete?(resultData, sql, db, info, status)
                }

            }
            else {
                let msgPointer = mysql_error(mysql)
                let msg:String?
                if msgPointer == nil{
                    msg = ""
                }
                else {
                    msg = String.init(cString: msgPointer!, encoding: .utf8)
                }
                __dispatch_async(.main) {  [unowned self] () -> Void in
                    complete?(nil, sql, db, msg, status)
                }
            }
        }
    }

    func showScheme(table: String, db: String, complete: DBConnectionQueryCompleteBlock?) {
        self.query(sql: "show full columns from " + table + ";")
    }
}

extension DBConnectionMySQL : SSHTunnelDelegate {
    func sshTunnelFailure(_ code: Int32, withInfo info: String) {
        self.delegate?.onConnectionError(err: .sshConnectionFailed, info: info)
    }

    func sshTunnelRemoteClosed() {
        // 断开所有连接
        self.mysql = nil
        self.close()
    }

    func sshTunnelSuccess(_ localHost: String, withPort localPort: Int32) {
        realConnectHost = localHost
        realConnectPort = Int(localPort)
        getTables(dbName: connection.db)
        getViews(dbName: connection.db)
        getDatabases()
        getProcedures(dbName: connection.db)
        getFunctions(dbName: connection.db)
    }
}
