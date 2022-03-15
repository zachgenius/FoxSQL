//
//  LocalDBManager.swift
//  FoxData 本地保存连接的数据库
//
//  Created by Zach Wang on 2019/3/10.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit
import SQLite

class LocalDBManager: NSObject {

    private var db:Connection? // 数据库连接

    private let conns = Table("connections")
    private let exId = Expression<String>("id")
    private let exType = Expression<Int>("type")
    private let exCreateTime = Expression<Int>("createTime")
    private let exAlias = Expression<String>("alias")
    private let exHost = Expression<String>("host")
    private let exPort = Expression<Int>("port")
    private let exUsername = Expression<String>("username")
    private let exPassword = Expression<String>("password")
    private let exDb = Expression<String>("db")
    private let exCharset = Expression<String>("charset")
    private let exIsSSH = Expression<Bool>("isSSH")
    private let exSSHHost = Expression<String>("SSHHost")
    private let exSSHUser = Expression<String>("SSHUser")
    private let exSSHPort = Expression<Int>("SSHPort")
    private let exSSHPassword = Expression<String>("SSHPassword")
    private let exSSHPubKey = Expression<String>("SSHPubKey")
    private let exSSHPrivKey = Expression<String>("SSHPrivKey")
    private let exSSHPrivPwdKey = Expression<String>("SSHPrivPwdKey")
    private let exSSHIsKey = Expression<Bool>("SSHIsKey")

    static let _sharedManager = LocalDBManager()
    class func get()->LocalDBManager {
        return _sharedManager
    }
    
    private override init() {
        super.init()
        self.initDB()
    }
    
    private func initDB(){
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        //如果不存在的话，创建一个名为db.sqlite3的数据库，并且连接数据库
        do{
            let db = try Connection("\(path)/db.sqlite3")
            db.busyTimeout = 5
            db.busyHandler({ tries in
                if tries >= 3 {
                    return false
                }
                return true
            })

            self.db = db

            try db.run(conns.create(ifNotExists: true, block: { (builder) in
                builder.column(exId, primaryKey: true)
                builder.column(exType)
                builder.column(exCreateTime)
                builder.column(exAlias)
                builder.column(exHost)
                builder.column(exPort)
                builder.column(exUsername)
                builder.column(exPassword)
                builder.column(exDb)
                builder.column(exCharset)
                builder.column(exIsSSH)
                builder.column(exSSHHost)
                builder.column(exSSHUser)
                builder.column(exSSHPort)
                builder.column(exSSHPassword)
                builder.column(exSSHPubKey)
                builder.column(exSSHPrivKey)
                builder.column(exSSHPrivPwdKey)
                builder.column(exSSHIsKey)
            }))

        } catch {
            print("db failed: \(error)")
        }
    }
    
    func getAllDB() -> [DBConnectionModel]{
        let conns = Table("connections")
        var output:[DBConnectionModel] = []
        do {
            for conn in try db!.prepare(conns){
                let model = makeItem(conn)
                output.append(model)
            }

            output = output.sorted { model, model2 in
                model.createTime < model2.createTime
            }
        }catch {
            print("db failed: \(error)")
        }
        return output
    }
    
    func saveDB(_ db:DBConnectionModel){
        let first = findDB(db.id)
        if first == nil { // 插入
            do {
                try self.db!.run(conns.insert(
                        exId <- db.id,
                        exType <- db.type.rawValue,
                        exCreateTime <- db.createTime,
                        exAlias <- db.alias,
                        exHost <- db.host,
                        exPort <- Int(db.port),
                        exUsername <- db.username,
                        exPassword <- db.password,
                        exDb <- db.db,
                        exCharset <- db.charset,
                        exIsSSH <- db.isSSH,
                        exSSHHost <- db.sshHost,
                        exSSHPort <- db.sshPort,
                        exSSHUser <- db.sshUser,
                        exSSHPassword <- db.sshPassword,
                        exSSHIsKey <- db.sshIsKey,
                        exSSHPubKey <- db.sshPubKey,
                        exSSHPrivKey <- db.sshPrivKey,
                        exSSHPrivPwdKey <- db.sshPrivPasswordPhrase
                    
                ))
            }catch {
                print("db failed: \(error)")
            }

        }else {
            let alice = conns.filter(exId == db.id)
            do {
                try self.db!.run(alice.update(
                    [exType <- db.type.rawValue,
                        exAlias <- db.alias,
                        exHost <- db.host,
                        exPort <- Int(db.port),
                        exUsername <- db.username,
                        exPassword <- db.password,
                        exDb <- db.db,
                        exCharset <- db.charset,
                        exIsSSH <- db.isSSH,
                        exSSHHost <- db.sshHost,
                        exSSHPort <- db.sshPort,
                        exSSHUser <- db.sshUser,
                        exSSHPassword <- db.sshPassword,
                        exSSHIsKey <- db.sshIsKey,
                        exSSHPubKey <- db.sshPubKey,
                        exSSHPrivKey <- db.sshPrivKey,
                        exSSHPrivPwdKey <- db.sshPrivPasswordPhrase
                    ]
                ))
            }catch {
                print("db failed: \(error)")
            }
        }

    }

    func findDB(_ id:String) -> DBConnectionModel?{
        let alice = conns.filter(exId == id)
        do {
            for conn in try db!.prepare(alice){
                let model = makeItem(conn)
                return model
            }

        }catch {
            print("db failed: \(error)")
        }
        return nil
    }
    
    func deleteDB(_ id:String){
        let alice = conns.filter(exId == id)
        do {
            try db!.run(alice.delete())
        }catch {
            print("db failed: \(error)")
        }
        
    }

    private func makeItem(_ conn:Row) -> DBConnectionModel{
        let model = DBConnectionModel()
        model.id = conn[exId]
        model.type = DBType(rawValue: conn[exType]) ?? .MySQL
        model.createTime = conn[exCreateTime]
        model.alias = conn[exAlias]
        model.host = conn[exHost]
        model.port = UInt32(conn[exPort])
        model.username = conn[exUsername]
        model.password = conn[exPassword]
        model.db = conn[exDb]
        model.charset = conn[exCharset]
        model.isSSH = conn[exIsSSH]
        model.sshHost = conn[exSSHHost]
        model.sshPort = conn[exSSHPort]
        model.sshPassword = conn[exSSHPassword]
        model.sshUser = conn[exSSHUser]
        model.sshPubKey = conn[exSSHPubKey]
        model.sshPrivKey = conn[exSSHPrivKey]
        model.sshPrivPasswordPhrase = conn[exSSHPrivPwdKey]
        model.sshIsKey = conn[exSSHIsKey]
        return model
    }
}

internal extension Connection {
    public var userVersion: Int32 {
        get { return Int32(try! scalar("PRAGMA user_version") as! Int64)}
        set { try! run("PRAGMA user_version = \(newValue)") }
    }
}
