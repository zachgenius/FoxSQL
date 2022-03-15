//
// 手机主页
// Created by Zach Wang on 2019-01-30.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import ESTabBarController_swift

///本类作为主controller的外层包裹, 可以整体控制内层的大小, 防止界面被覆盖
class PhMainOuterController : BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mainController = PhMainController()
        mainController.outer = self
        mainController.view.frame = CGRect.init(x: 0, y: topMargin, width: self.view.bounds.width, height: self.view.bounds.height - topMargin)
        mainController.tabBarItem = nil
        self.addChild(mainController)
        self.view.addSubview(mainController.view)
    }
}


class PhMainController : ESTabBarController {
    weak var outer:PhMainOuterController? {
        didSet{
            //导航烂按钮
            initNavBarItems()
        }
    }
    
    var leftListController : LeftSelectController?
    var sqlInputController: SQLInputController?
    var queryResultController : QueryResultController?
    var sqlMessageController : SQLMessageController?

    var isInit = true

    let dbManager:DBConnectionManager = DBConnectionManager()
    var currentDB:DBDatabaseModel? {
        didSet {
            if currentDB != nil{
//                topView?.setData(db: currentDB!.name, server: currentDB!.serverName)
                outer?.title = currentDB!.name + " (\(currentDB!.serverName))"
            }
        }
    }
    
    var leftMenuArea:SideMenu?
    
    ///键盘上方的toolbar
    private let keywordToolbar:KeywordToolbar = KeywordToolbar()
    
    ///关键字的列表
    private let keywordMenu:KeywordMenu = KeywordMenu()
    
    ///用于记录上一次搜索到的keyword
    private var lastKeyword:KeywordModel?
    
    ///使用的是虚拟键盘还是外置键盘
    private var isVirtualKeyboard = false
    
    override var keyCommands: [UIKeyCommand]? {
        if keywordMenu.keywords.isEmpty {
            return []
        }
        
        return  [
            UIKeyCommand.init(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(navUp)),
            UIKeyCommand.init(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(navDown)),
            UIKeyCommand.init(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(navEsc)),
            UIKeyCommand.init(input: "\r", modifierFlags: [], action: #selector(navEnt))
        ]
    }
    
    @objc private func navUp(){
        self.keywordMenu.moveFocusUp()
    }
    
    @objc private func navDown(){
        self.keywordMenu.moveFocusDown()
    }
    
    @objc private func navEsc(){
        self.keywordMenu.view.isHidden = true
        self.keywordMenu.keywords.removeAll()
    }
    
    @objc private func navEnt(){
        self.keywordMenu.confirm()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager.delegate = self
        
        //左侧列表
        leftListController = LeftSelectController()
        leftListController?.reqDelegate = self

        //添加输入列表
        sqlInputController = SQLInputController()
        sqlInputController?.view.autoresizingMask = [.flexibleHeight, .flexibleBottomMargin]
        sqlInputController?.tabBarItem = ESTabBarItem.init(BigTitleBarItemContentView(), title:"SQL")
        sqlInputController?.delegate = self
        
        queryResultController = QueryResultController()
        queryResultController?.delegate = self
        queryResultController?.view.autoresizingMask = [.flexibleHeight, .flexibleTopMargin]
        queryResultController?.tabBarItem = ESTabBarItem.init(BigTitleBarItemContentView(), title:"Results")

        sqlMessageController = SQLMessageController()
        sqlMessageController?.view.autoresizingMask = [.flexibleHeight, .flexibleTopMargin]
        sqlMessageController?.tabBarItem = ESTabBarItem.init(BigTitleBarItemContentView(), title:"Messages")

        self.viewControllers = [sqlInputController!, queryResultController!, sqlMessageController!]
        
        leftMenuArea = SideMenu()
        leftMenuArea?.setContentView(leftListController!.view)
        leftMenuArea?.menuWidth = 280
        leftMenuArea?.addSelfToRoot()
        
        self.view.addSubview(keywordMenu.view)
        
        //默认toolbar在屏幕下方
        let width = self.view.bounds.width
        let screenHeight = self.view.bounds.height
        keywordToolbar.view.frame = CGRect.init(x: 0, y: screenHeight, width: width, height: KeywordToolbar.barHeight)
        self.view.addSubview(keywordToolbar.view)
        
        //关键字选中后替换
        let callback:((KeywordModel) -> Void) = {[unowned self] keyword in
            let textView = self.sqlInputController!.getTextView()
            let range = textView.selectedRange
            let beginning = textView.beginningOfDocument
            let start = textView.position(from: beginning, offset: range.location)
            let end = textView.position(from: start!, offset: range.length)
            let wordRange = textView.tokenizer.rangeEnclosingPosition(end!, with: .word, inDirection: UITextDirection.init(rawValue: UITextLayoutDirection.left.rawValue))
            if wordRange == nil {
                textView.replace(textView.textRange(from: start!, to: end!)!, withText: keyword.value + " ")
            }
            else {
                textView.replace(wordRange!, withText: keyword.value + " ")
            }
        }
        
        keywordMenu.keywordCallback = callback
        keywordToolbar.keywordCallback = callback
        keywordToolbar.keyboardCloseAction = {[unowned self] in
            self.view.endEditing(true)
        }
    }

    func connectServer(_ server:DBConnectionModel){
        showLoading("Connecting...")
        dbManager.connectServer(server)

        let db = DBDatabaseModel()
        db.name = server.db
        db.serverName = server.host
        db.isSample = server.isSample
        self.currentDB = db
        
        queryResultController?.showResult = server.isSample || SubscriptionManager.get().isSubscriptionValid
        
    }

    private func initNavBarItems(){
        // title
        initTitleBar()

        //drop menu
        initDropMenu()


        // nav items
        
        let leftMenuButton = self.generateNavBarIconItem(imageName: "menu", target: self, action: #selector(menuItemAction))

        
        let newButton = self.generateNavBarIconItem(imageName: "plus", target: self, action: #selector(newConnAction))

        // settings
        let settingButton = self.generateNavBarIconItem(imageName: "setting", target: self, action: #selector(settingItemAction))


        // run
        let runButton = self.generateNavBarIconItem(imageName: "run", target: self, action: #selector(runItemAction))


        outer?.navigationItem.leftBarButtonItems = [leftMenuButton, newButton]
        outer?.navigationItem.rightBarButtonItems = [runButton, settingButton]
    }

    func initTitleBar(){
        //TODO 下个版本特殊titlebar
//        topView = MainTitleBar.init(type: .roundedRect)
//        topView?.frame = self.navigationController!.navigationBar.bounds
//        topView?.initViews()
//        topView?.addTarget(self, action: #selector(topViewAction), for: .touchUpInside)
//        self.navigationItem.titleView = topView

        if currentDB == nil{
            outer?.title = "No Connection"
        }
        else{
            outer?.title = currentDB!.name + " (\(currentDB!.serverName))"
        }
    }

    private func initDropMenu(){
        let configuration = FTConfiguration.shared
        configuration.menuWidth = 170
        configuration.textColor = UIColor.darkText
        configuration.backgoundTintColor = UIColor("#fff5eb")
        configuration.cellSelectionStyle = .gray
    }

    /// MARK - Nav Bar Item Actions
    
    @objc func menuItemAction(){
        self.leftMenuArea?.show()
    }

    @objc func runItemAction(){
        if currentDB == nil || currentDB!.name.isEmpty{
            showFailurePop("No Connection", "Please connect to a database before running SQL commands.")
            return
        }
        let text = sqlInputController!.getText()
        if !text.isEmpty{
            dbManager.query(sql: text, db: currentDB!.name)
        }
    }

    @objc func newConnAction(){
        let connContr = NewConnectionController()
        connContr.delegate = self
        let nav = UINavigationController.init(rootViewController: connContr)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)

    }

    @objc func settingItemAction(){
        let nav = UINavigationController.init(rootViewController: SettingsController())
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    @objc func topViewAction(){
        leftListController?.showTab(1)
    }

    override func viewDidAppear(_ animated: Bool) {
        if isInit && currentDB == nil{
            isInit = false
            newConnAction()
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layoutAllSubviews(self.traitCollection.horizontalSizeClass == .compact)
    }
    
    /// 用来判断是否是手机竖屏(iPad分割小屏)模式
    open func layoutAllSubviews(_ isWidthCompactLayout:Bool){
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseNotify(_:)), name: NSNotification.Name(rawValue: "PurchaseNotify"), object: nil)
        queryResultController?.showResult = currentDB == nil || currentDB!.isSample || SubscriptionManager.get().isSubscriptionValid
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func purchaseNotify(_ notify:Notification) {
        queryResultController?.showResult = currentDB == nil || currentDB!.isSample || SubscriptionManager.get().isSubscriptionValid
    }
}

extension PhMainController : LSLRequestDelegate{
    /// MARK - OpeningDBListDelegate
    /// 从列表里收到command
    func lslSendSql(sendSql: String, db: String, run: Bool, newTab: Bool) {
        self.sqlInputController?.setText(sendSql, title: nil, newTab: true)
        self.sqlInputController?.view.setNeedsLayout()
        dbManager.query(sql: sendSql, db: currentDB?.name ?? "")
        leftMenuArea?.hide()
    }

    func lslSwitchDB(switchDB: String) {
        showLoading()
        let db = DBDatabaseModel()
        db.name = switchDB
        db.type = currentDB!.type
        db.serverName = currentDB!.serverName
        self.currentDB = db
        dbManager.switchDB(dbName: switchDB)
        leftListController?.showTab(0)
    }

    func lslRequestLoadAllDatabases() {
        dbManager.getDatabases()
    }

    func lslRequestProcedures(_ db: String) {
        dbManager.getProcedures(dbName: db)
        leftMenuArea?.hide()
    }

    func lslRequestTables(_ db: String) {
        dbManager.getTables(dbName: db)
    }

    func lslRequestViews(_ db: String) {
        dbManager.getViews(dbName: db)
    }

    func lslRequestFunctions(_ db: String) {
        dbManager.getFunctions(dbName: db)
    }

    func lslNewTable(_ db: String) {
        let controller = AddModifyTableController()
        controller.db = db
        controller.connectManager = self.dbManager
        controller.callback = {[unowned self] (table, db, success, info) in
            self.lslRequestTables(db)
            self.showSuccessPop("CREATE TABLE", "Success!")
        }

        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .formSheet
        self.present(nav, animated: true)
        leftMenuArea?.hide()
    }

    func lslShowCreate(_ type: ShowCreateType, db: String, toShow: String) {
        dbManager.getCreateValue(type: type, db: db, name: toShow)
        leftMenuArea?.hide()
    }

    func lslShowDangerProcessAlert(_ title: String, hint: String, sql: String, db: String) {
        let alert = SQLProcessAlertController()
        alert.title = title
        alert.hint = hint
        alert.sql = sql
        alert.db = db
        alert.connectManager = dbManager
        alert.callback = { [unowned self](sql, db, success, info) in
            if sql.lowercased().hasPrefix("drop table"){
                self.dbManager.getTables(dbName: self.currentDB!.name)
            }
            else if sql.lowercased().hasPrefix("drop view"){
                self.dbManager.getViews(dbName: self.currentDB!.name)
            }
            else if sql.lowercased().hasPrefix("drop procedure"){
                self.dbManager.getProcedures(dbName: self.currentDB!.name)
            }
            else if sql.lowercased().hasPrefix("drop function"){
                self.dbManager.getFunctions(dbName: self.currentDB!.name)
            }

        }
        let nav = UINavigationController(rootViewController: alert)
        nav.modalPresentationStyle = .formSheet
        self.present(nav, animated: true)
        leftMenuArea?.hide()
    }

    func lslInsertData(_ table: String, db: String) {
//        let controller = AddModifyTableController()
//        controller.db = db
//        let tb = DBTableModel()
//        tb.name = table
//        controller.originalTable = tb
//        controller.callback = {[unowned self] (table, db, success, info) in
//            //TODO 下个版本
//        }
//
//        let nav = UINavigationController(rootViewController: controller)
//        nav.modalPresentationStyle = .formSheet
//        self.present(nav, animated: true)
    }

    func lslAlterTable(_ table: String, db: String) {
        //TODO 下个版本
    }
}

extension PhMainController:DBConnectionManagerDelegate{
    func onServerConnected() {
        hideLoading()
        KeywordManager.get().clearKeywords()
    }

    func onFetchDatabases(results: [String]?, info: String?) {
        if results != nil{
            leftListController?.totalDBs = results
        }
        else {
            leftListController?.totalDBs = []
            showFailurePop("Failed to get databases", info)
        }
        addLog(info)
    }

    func onFetchTables(results:[String:[String]]?, info:String?){
        if results != nil {
            self.currentDB?.tables = results

        }
        else {
            self.currentDB?.tables = ["Failed":[]]
        }
        self.leftListController?.currentDB = self.currentDB
        addLog(info)
    }

    func onFetchProcedures(results: [String: [String]]?, info: String?) {
        if results != nil {
            self.currentDB?.procedures = results

        }
        else {
            self.currentDB?.procedures = ["Failed":[]]
            switchToMessage()
        }
        self.leftListController?.currentDB = self.currentDB
        addLog(info)
    }

    func onFetchViews(results: [String: [String]]?, info: String?) {
        if results != nil {
            self.currentDB?.views = results

        }
        else {
            self.currentDB?.views = ["Failed":[]]
            switchToMessage()
        }
        self.leftListController?.currentDB = self.currentDB
        addLog(info)
    }

    func onFetchFunctions(results: [String: [String]]?, info: String?) {
        if results != nil {
            self.currentDB?.functions = results

        }
        else {
            self.currentDB?.functions = ["Failed":[]]
            switchToMessage()
        }
        self.leftListController?.currentDB = self.currentDB
        addLog(info)
    }

    func onFetchCreateValue(result: String?, type: ShowCreateType, name: String, db: String, info: String?) {
        if result != nil{
            sqlInputController?.setText(result!, title: name, newTab: true)
            switchToSql()
        }
        else {
            switchToMessage()
        }
        addLog(info)
    }

    func onQueryResult(result:[[DBQueryResultItemModel]]?, sql:String, info:String?){
        if result != nil {
            switchToSheet()
            setDataResult(result!)
        }
        else {
            switchToMessage()
        }
        addLog(info)
    }

    func onConnectionError(err: DBConnectionError, info: String?) {
        hideLoading()
        switchToMessage()
        addLog(info)
        showFailurePop("Connection Error", info)
    }
    
    func addLog(_ log:String?){
        if log != nil {
            sqlMessageController?.addLog(log!)
        }
    }
    
    func setDataResult(_ result:[[DBQueryResultItemModel]]){
        self.queryResultController?.data = result
    }
    
    func switchToSql(){
        self.selectedIndex = 0
    }
    
    func switchToSheet(){
        self.selectedIndex = 1
        
    }
    func switchToMessage(){
        self.selectedIndex = 2
    }
}

extension PhMainController : QueryResultDelegate {
    func queryResultCopy(indexPaths:[IndexPath]){
        if indexPaths.isEmpty || self.queryResultController?.data == nil{
            return
        }
        let ip = indexPaths[0]
        let item:DBQueryResultItemModel = self.queryResultController!.data![ip.section][ip.row-1]
        if item.type == .blob{
            showSuccessPop("Copy", "BLOB item cannot be copied")
        }
        else {
            let pasteboard = UIPasteboard.general
            pasteboard.string = item.text
            showSuccessPop("Copy", "Copy succeeded")
        }

    }
    func queryResultPreview(indexPaths:[IndexPath]){
        if indexPaths.isEmpty || self.queryResultController?.data == nil{
            return
        }
        let ip = indexPaths[0]
        let item:DBQueryResultItemModel = self.queryResultController!.data![ip.section][ip.row-1]
        let contr = DBResultItemPreviewController()
        contr.resultItem = item
        contr.dbManager = self.dbManager
        let nav = UINavigationController.init(rootViewController: contr)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)

    }
    func queryResultEdit(indexPaths:[IndexPath]){
//todo 下个版本
    }
    func queryResultDelete(indexPaths:[IndexPath]){
//todo 下个版本
    }
    
}

extension PhMainController:NewConnectionDelegate {
    func onConnect(_ conn: DBConnectionModel) {
        self.connectServer(conn)
    }
}

extension PhMainController : SQLInputDelegate {
    func onRevokeChainCreated(_ chain: [String], _ cursorPoint:CGPoint?) {
        var keywords:[KeywordModel] = []
        if chain.count == 0 {
            self.lastKeyword = nil
        }
        else{
            
            //按照上次保留的来
            if lastKeyword != nil {
                //最后一个是搜索内容
                if chain.count % 2 == 1{
                    
                    let item = chain[chain.count - 1]
                    keywords = lastKeyword!.sub.filter({ (keyword) -> Bool in
                        return keyword.title.uppercased().starts(with: item.uppercased())
                    })
                } else { // 最后一个是.列出调用内容
                    keywords = lastKeyword!.sub
                }
            }
            else{ //重新搜索
                //最后一个是搜索内容
                var count = chain.count - 1
                
                for item in chain {
                    //当前位置是最后一个
                    if count == 0{
                        if lastKeyword != nil {
                            if item == "."{
                                keywords = lastKeyword!.sub
                            }
                            else {
                                keywords = lastKeyword!.sub.filter({ (keyword) -> Bool in
                                    return keyword.title.uppercased().starts(with: item.uppercased())
                                })
                            }
                        }
                        else if chain.count == 1{
                            let arr = KeywordManager.get().keywords.filter({ (keyword) -> Bool in
                                return keyword.title.uppercased().starts(with: item.uppercased())
                            })
                            keywords = arr
                        }else {
                            keywords = []
                        }
                        
                        break
                    }
                    
                    if item != "."{
                        if count == chain.count - 1{//第一个
                            let arr = KeywordManager.get().keywords.filter({ (keyword) -> Bool in
                                return keyword.type == .table && keyword.title.uppercased() == item.uppercased()
                            })
                            if arr.count > 0 {
                                self.lastKeyword = arr[0]
                            }
                        }
                        else if lastKeyword != nil {
                            let arr = self.lastKeyword!.sub.filter({ (keyword) -> Bool in
                                return keyword.title.uppercased() == item.uppercased()
                            })
                            if arr.count > 0 {
                                self.lastKeyword = arr[0]
                            }
                            else {
                                self.lastKeyword = nil
                            }
                        }
                    }
                    
                    count = count - 1
                }
                
            }
        }
        if !isVirtualKeyboard {
            self.keywordMenu.keywords = keywords
            if cursorPoint != nil {
                let inputOrigin = self.sqlInputController!.getInputAreaOrigin()
                self.keywordMenu.updateFrame(inputOrigin.x + cursorPoint!.x - 50, inputOrigin.y + cursorPoint!.y + 20)
            }else{
                self.keywordMenu.updateFrame(0, 0)
            }
        }
        else {
            self.keywordToolbar.keywords = keywords
        }
        
    }
}

//keyboard
extension PhMainController {
    @objc private func keyboardDidShow(_ notif:Notification){
        let userInfo = notif.userInfo
        let value = userInfo![UIResponder.keyboardFrameEndUserInfoKey]
        let keyboardRect = value as! CGRect
        let height = keyboardRect.height
        keywordToolbar.keywords = []
        keywordMenu.keywords = []
        if height > 100 {//虚拟键盘
            isVirtualKeyboard = true
            UIView.animate(withDuration: 0.2) {[unowned self] in
                let screenWidth = self.view.bounds.width
                let screenHeight = self.view.bounds.height
                self.keywordToolbar.view.frame = CGRect.init(x: 0, y: screenHeight - height - KeywordToolbar.barHeight, width: screenWidth, height: KeywordToolbar.barHeight)
            }
        }
        else{//外接键盘
            isVirtualKeyboard = false
        }
    }
    
    @objc private func keyboardDidHide(_ notif:Notification){
        keywordToolbar.keywords = []
        keywordMenu.keywords = []
        
        if self.keywordToolbar.view.frame.origin.y < self.view.bounds.height {
            UIView.animate(withDuration: 0.2) {[unowned self] in
                let screenWidth = self.view.bounds.width
                let screenHeight = self.view.bounds.height
                self.keywordToolbar.view.frame = CGRect.init(x: 0, y: screenHeight, width: screenWidth, height: KeywordToolbar.barHeight)
            }
        }
        //这里为了防止连接上键盘后, 不会调用didShow方法
        isVirtualKeyboard = false
    }
}
