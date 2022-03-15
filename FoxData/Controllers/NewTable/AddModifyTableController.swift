// 添加或修改表
// Created by Zach Wang on 2019-02-27.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit
import ESTabBarController_swift

typealias AddModifyTableCallback = (_ table:String, _ db:String, _ success:Bool, _ info:String?) -> Void

class AddModifyTableController :ESTabBarController  {

    weak var connectManager:DBConnectionManager?
    var callback:AddModifyTableCallback?
    var originalTable:DBTableModel?
    var db:String?
    
    private var columnController:AMColumnController?
    private var indexController:AMIndexController?
    
    private var updateSQLs:[String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        if originalTable?.name == nil{
            self.title = "New Table"
            originalTable = DBTableModel()
        }
        else {
            self.title = originalTable?.name
        }

        let closeButton = self.generateNavBarIconItem(imageName: "close", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton
        let checkButton = self.generateNavBarIconItem(imageName: "check", target: self, action: #selector(saveAction), tintColor: UIColor.red)
        self.navigationItem.rightBarButtonItem = checkButton

        columnController = AMColumnController()
        if originalTable?.columns != nil {
            var arr:[DBTableColumnPropModel] = []
            arr.append(contentsOf: originalTable!.columns!)
            columnController?.columns = arr
        }

        let columnTab = ESTabBarItem.init(title: "Columns", image:  UIImage.init(named: "left-datasheet"))
        columnController?.tabBarItem = columnTab
        
        indexController = AMIndexController()
//        indexController?.indexes = newTable.indexes
        let indexTab = ESTabBarItem.init(title: "Indexes", image:  UIImage.init(named: "icon-index"))
        indexController?.tabBarItem = indexTab
//        self.viewControllers = [columnController!, indexController!]

    //TODO 先只用column
        self.viewControllers = [columnController!]

    }

    @objc func closeAction(){
        self.dismiss(animated: true)
    }

    @objc func saveAction(){
        //新表
        if originalTable?.name == nil {
            let columns = columnController!.columns
            if columns == nil || columns?.count == 0{
                showFailurePop("Columns", "Please add a column")
                return
            }

            let controller = ConfirmAddTableController()
            var primaryKeys:[String] = []
            controller.callback = { [unowned self] (name, charset, collation, engine) in
                let sql = NSMutableString.init(string: "CREATE TABLE ")
                sql.append(name)
                sql.append(" (")
                for item in columns! {
                    sql.append("\n `\(item.name)` \(item.type.rawValue)")
                    if item.length > 0 {
                        sql.append("(\(item.length))")
                    }
                    if item.primary {
                        primaryKeys.append(item.name)
                    }
                    if !item.nullable {
                        sql.append(" NOT NULL")
                    }
                    if item.autoIncrement {
                        sql.append(" AUTO_INCREMENT")
                    }
                    if item.comment != nil && item.comment != ""{
                        sql.append(" COMMENT '\(item.comment!)'")
                    }
                    if item.defaultValue != nil && item.comment != "" {
                        sql.append(" DEFAULT '\(item.defaultValue!)'")
                    }
                    sql.append(",")
                }

                if primaryKeys.count > 0 {
                    sql.append("\n PRIMARY KEY (")
                    for item in primaryKeys {
                        sql.append("`\(item)`,")
                    }
                    
                    sql.replaceCharacters(in: NSRange.init(location: sql.length - 1, length: 1), with: "")
                    sql.append(")")
                }
                else{
                    sql.replaceCharacters(in: NSRange.init(location: sql.length - 1, length: 1), with: "")
                }

                sql.append("\n) ENGINE = \(engine) CHARACTER SET = \(charset) COLLATE = \(collation);")

                //显示提示
                let alert = SQLProcessAlertController()
                alert.title = "CREATE TABLE"
                alert.hint = "Please confirm the statement carefully"
                alert.sql = String(sql)
                alert.db = self.db ?? ""
                alert.connectManager = self.connectManager
                alert.callback = { [unowned self](sql, db, success, info) in
                    if success {
                        self.callback?(name, db, success, info)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {[unowned self] in
                             self.dismiss(animated: true)
                        })
                    }

                }
                let nav = UINavigationController(rootViewController: alert)
                nav.modalPresentationStyle = .formSheet
                self.present(nav, animated: true)
            }

            self.navigationController?.pushViewController(controller, animated: true)

        }
        else { // 修改表
            let columns = columnController!.columns!
            let deleted = columnController!.deletedColumns
        }
    }

}

