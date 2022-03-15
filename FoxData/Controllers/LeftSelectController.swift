// 选择表，view，procedure等
// Created by Zach Wang on 2019-04-09.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit
import ESTabBarController_swift

class LeftSelectController : ESTabBarController {

    weak var reqDelegate: LSLRequestDelegate?

    let dbController = LSLDatabasesController()
    let viewsController = LSLViewsController()
    let tablesController = LSLTablesController()
    let proceduresController = LSLProceduresController()
    let functionsController = LSLFunctionsController()

    var currentDB: DBDatabaseModel? = nil{
        didSet {
            tablesController.currentDB = currentDB
        }
    }

    var totalDBs:[String]? {
        didSet {
            dbController.totalDBs = totalDBs
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var columnTab = ESTabBarItem.init(DefaultTabContentView(), image:  UIImage.init(named: "left-datasheet"))
        tablesController.tabBarItem = columnTab
        tablesController.parentController = self

        columnTab = ESTabBarItem.init(DefaultTabContentView(), image:  UIImage.init(named: "left-data"))
        dbController.tabBarItem = columnTab
        dbController.parentController = self

        columnTab = ESTabBarItem.init(DefaultTabContentView(), image:  UIImage.init(named: "left-views"))
        viewsController.tabBarItem = columnTab
        viewsController.parentController = self

        columnTab = ESTabBarItem.init(DefaultTabContentView(), image:  UIImage.init(named: "left-procedure"))
        proceduresController.tabBarItem = columnTab
        proceduresController.parentController = self

        columnTab = ESTabBarItem.init(DefaultTabContentView(), image:  UIImage.init(named: "left-function"))
        functionsController.tabBarItem = columnTab
        functionsController.parentController = self

        self.viewControllers = [tablesController, dbController, viewsController, proceduresController, functionsController]
    }

    func showTab(_ index:Int){
        self.selectedIndex = index
    }
}

protocol LSLRequestDelegate: class {
    func lslSendSql(sendSql:String, db:String, run:Bool, newTab: Bool)
    func lslSwitchDB(switchDB: String)
    func lslRequestLoadAllDatabases()
    func lslRequestProcedures(_ db:String)
    func lslRequestTables(_ db:String)
    func lslRequestViews(_ db:String)
    func lslRequestFunctions(_ db:String)
    func lslNewTable(_ db:String)
    func lslShowCreate(_ type:ShowCreateType, db:String, toShow:String)

    func lslShowDangerProcessAlert(_ title:String, hint:String, sql:String, db:String)
    func lslInsertData(_ table:String, db:String)
    func lslAlterTable(_ table:String, db:String)
}

@objc enum ShowCreateType:Int {
    case table
    case view
    case procedure
    case function
}

