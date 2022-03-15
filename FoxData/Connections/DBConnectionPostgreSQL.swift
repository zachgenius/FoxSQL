//
//  DBConnectionPostgreSQL.swift
//  FoxData
//
//  Created by Zach Wang on 3/28/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit

class DBConnectionPostgreSQL: DBConnection {
    weak var delegate: DBConnectionCallBackDelegate?
    
    private(set) var connection: DBConnectionModel
    
    private let queryQueue = DispatchQueue(label: "pgConn", qos: .background)

    private var sshTunnel:SSHTunnel?
    
    ///实际连接的地址， 有可能是远程， 有可能是本机转发
    private var realConnectHost = ""
    private var realConnectPort = 5432

    var localListeningPort = 10100
    
    private var bridge:PGBridge?
    
    init(_ connection:DBConnectionModel){
        self.connection = connection
        self.bridge = PGBridge();
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
                self.testPostgresAuth(server, localhost, UInt32(localport), callback)

            }) { (errCode, msg) in
                __dispatch_async(.main) {() -> Void in
                    callback(-1, "SSH Authentication Failure")
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
            self.testPostgresAuth(server, host, port, callback)
        }
    }

    private static func testPostgresAuth(_ server:DBConnectionModel, _ host:String, _ port:UInt32, _ callback: @escaping (Int, String) -> Void){
        let bridge = PGBridge()
        bridge.checkAuth(server, host: host, port: Int32(port)) { (code, msg) in
            callback(Int(code),msg)
        }
    }
    
    func connect() {
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
    
    func getDatabases() {
        
    }
    
    func getTables(dbName: String) {
        
    }
    
    func getViews(dbName: String) {
        
    }
    
    func getProcedures(dbName: String) {
        
    }
    
    func getFunctions(dbName: String) {
        
    }
    
    func query(sql: String, db: String) {

    }
    
    func cacheDBKeywords(dbName: String) {
        
    }
    
    func getCreateValue(type: ShowCreateType, db: String, name: String) {
        
    }
    
    func close() {
        self.bridge?.close();
    }
    
    func addQuery(sql: String, db: String, complete: DBConnectionQueryCompleteBlock?) {
        
    }
    
    func showScheme(table: String, db: String, complete: DBConnectionQueryCompleteBlock?) {
        
    }
    

}

extension DBConnectionPostgreSQL:SSHTunnelDelegate {
    func sshTunnelFailure(_ code: Int32, withInfo info: String) {
        self.delegate?.onConnectionError(err: .sshConnectionFailed, info: info)
    }
    
    func sshTunnelRemoteClosed() {
        // 断开所有连接
        
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
