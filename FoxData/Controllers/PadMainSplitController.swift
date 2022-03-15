//
// Pad主页. 自己控制当前界面的内容
// Created by Zach Wang on 2019-01-22.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

class PadMainSplitController: BaseViewController {
    
    let dbListWidth = 280
    let inputDefaultHeight = 300

    var leftListController : LeftSelectController?
    
    var sqlInputController: SQLInputController?

    fileprivate var queryArea : QueryArea?
    
    var isInit = true

    let dbManager:DBConnectionManager = DBConnectionManager()
    var currentDB:DBDatabaseModel? {
        didSet {
            if currentDB != nil{
//                topView?.setData(db: currentDB!.name, server: currentDB!.serverName)
                self.title = currentDB!.name + " (\(currentDB!.serverName))"
            }
        }
    }

//    private var topView:MainTitleBar?

    private let dividerColor = UIColor.black
    
    private let keywordMenu:KeywordMenu = KeywordMenu()
    
    ///键盘上方的toolbar
    private let keywordToolbar:KeywordToolbar = KeywordToolbar()
    
    ///使用的是虚拟键盘还是外置键盘
    private var isVirtualKeyboard = false
    
    //用于记录上一次搜索到的keyword
    private var lastKeyword:KeywordModel?
    
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

    override func viewDidLoad() {
        super.viewDidLoad()

        dbManager.delegate = self

        //导航烂按钮
        initNavBarItems()

        //左侧列表
        leftListController = LeftSelectController()
        leftListController?.reqDelegate = self
        self.addChild(leftListController!)
        self.view.addSubview(leftListController!.view)

        //分割线
        let divider1 = UIView()
        divider1.backgroundColor = dividerColor
        self.view.addSubview(divider1)

        //添加输入列表
        sqlInputController = SQLInputController()
        sqlInputController?.delegate = self
        self.addChild(sqlInputController!)
        sqlInputController?.view.autoresizingMask = [.flexibleHeight, .flexibleBottomMargin]
        self.view.addSubview(sqlInputController!.view)

        //分割线
        let divider2 = UIView()
        divider2.backgroundColor = dividerColor
        self.view.addSubview(divider2)

        //添加结果页面
        queryArea = QueryArea()
        queryArea?.dbManager = self.dbManager
        queryArea?.view.autoresizingMask = [.flexibleHeight, .flexibleTopMargin]
        self.addChild(queryArea!)
        self.view.addSubview(queryArea!.view)

        //库列表
        leftListController?.view.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(topMargin)
            maker.left.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.width.equalTo(dbListWidth)
        }

        divider1.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.left.equalTo(leftListController!.view.snp.right)
            maker.width.equalTo(0.5)
        }

        //输入列表
        sqlInputController?.view.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(topMargin)
            maker.height.equalTo(inputDefaultHeight)
            maker.left.equalTo(divider1.snp.right)
            maker.right.equalToSuperview()
        }

        divider2.snp.makeConstraints { maker in
            maker.top.equalTo(sqlInputController!.view.snp.bottom)
            maker.right.equalToSuperview()
            maker.left.equalTo(divider1.snp.right)
            maker.height.equalTo(0.5)
        }

        //结果列表
        queryArea!.view.snp.makeConstraints { maker in
            maker.top.equalTo(divider2.snp.bottom)
            maker.bottom.equalToSuperview()
            maker.left.equalTo(divider1.snp.right)
            maker.right.equalToSuperview()
        }
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseNotify(_:)), name: NSNotification.Name(rawValue: "PurchaseNotify"), object: nil)
        
        queryArea?.queryResultController?.showResult = currentDB == nil || currentDB!.isSample || SubscriptionManager.get().isSubscriptionValid
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func purchaseNotify(_ notify:Notification) {
         queryArea?.queryResultController?.showResult = self.currentDB?.isSample == true || SubscriptionManager.get().isSubscriptionValid
    }

    func connectServer(_ server:DBConnectionModel){
        showLoading("Connecting...")
        dbManager.connectServer(server)

        let db = DBDatabaseModel()
        db.name = server.db
        db.serverName = server.host
        db.isSample = server.isSample
        self.currentDB = db
        
        queryArea?.queryResultController?.showResult = server.isSample || SubscriptionManager.get().isSubscriptionValid
    }

    private func initNavBarItems(){
        // title
        initTitleBar()
        
        //drop menu
        initDropMenu()
        
        
        // nav items
        let newButton = self.generateNavBarIconItem(imageName: "plus", target: self, action: #selector(newConnAction))

        // settings
        let settingButton = self.generateNavBarIconItem(imageName: "setting", target: self, action: #selector(settingItemAction))

        
        // run
        let runButton = self.generateNavBarIconItem(imageName: "run", target: self, action: #selector(runItemAction))
        

        self.navigationItem.leftBarButtonItems = [newButton, settingButton]
        self.navigationItem.rightBarButtonItems = [runButton]
    }

    func initTitleBar(){
        //TODO 下个版本特殊titlebar
//        topView = MainTitleBar.init(type: .roundedRect)
//        topView?.frame = self.navigationController!.navigationBar.bounds
//        topView?.initViews()
//        topView?.addTarget(self, action: #selector(topViewAction), for: .touchUpInside)
//        self.navigationItem.titleView = topView
        
        if currentDB == nil{
            self.title = "No Connection"
        }
        else{
            self.title = currentDB!.name + " (\(currentDB!.serverName))"
        }
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
    
    private func initDropMenu(){
        let configuration = FTConfiguration.shared
        configuration.menuWidth = 170
        configuration.textColor = UIColor.darkText
        configuration.backgoundTintColor = UIColor("#fff5eb")
        configuration.cellSelectionStyle = .gray
    }

    /// MARK - Nav Bar Item Actions

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

}

extension PadMainSplitController : LSLRequestDelegate{
    /// MARK - OpeningDBListDelegate
    /// 从列表里收到command
    func lslSendSql(sendSql: String, db: String, run: Bool, newTab: Bool) {
        self.sqlInputController?.setText(sendSql, title: nil, newTab: true)
        self.sqlInputController?.view.setNeedsLayout()
        dbManager.query(sql: sendSql, db: currentDB?.name ?? "")
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
    }

    func lslShowCreate(_ type: ShowCreateType, db: String, toShow: String) {
        dbManager.getCreateValue(type: type, db: db, name: toShow)
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

extension PadMainSplitController:DBConnectionManagerDelegate{
    func onServerConnected() {
        KeywordManager.get().clearKeywords()
        hideLoading()
    }

    func onFetchDatabases(results: [String]?, info: String?) {
        if results != nil{
            leftListController?.totalDBs = results
        }
        else {
            leftListController?.totalDBs = []
            showFailurePop("Failed to get databases", info)
        }
        queryArea?.addLog(info)
    }

    func onFetchTables(results:[String:[String]]?, info:String?){
        if results != nil {
            self.currentDB?.tables = results

        }
        else {
            self.currentDB?.tables = ["Failed":[]]
//            showFailurePop("Failed to get tables", info)
        }
        self.leftListController?.currentDB = self.currentDB
        queryArea?.addLog(info)
    }

    func onFetchProcedures(results: [String: [String]]?, info: String?) {
        if results != nil {
            self.currentDB?.procedures = results

        }
        else {
            self.currentDB?.procedures = ["Failed":[]]
//            showFailurePop("Failed to get stored procedures", info)
            queryArea?.switchToMessage()
        }
        self.leftListController?.currentDB = self.currentDB
        queryArea?.addLog(info)
    }

    func onFetchViews(results: [String: [String]]?, info: String?) {
        if results != nil {
            self.currentDB?.views = results

        }
        else {
            self.currentDB?.views = ["Failed":[]]
//            showFailurePop("Failed to get views", info)
            queryArea?.switchToMessage()
        }
        self.leftListController?.currentDB = self.currentDB
        queryArea?.addLog(info)
    }

    func onFetchFunctions(results: [String: [String]]?, info: String?) {
        if results != nil {
            self.currentDB?.functions = results

        }
        else {
            self.currentDB?.functions = ["Failed":[]]
            queryArea?.switchToMessage()
        }
        self.leftListController?.currentDB = self.currentDB
        queryArea?.addLog(info)
    }

    func onFetchCreateValue(result: String?, type: ShowCreateType, name: String, db: String, info: String?) {
        if result != nil{
            sqlInputController?.setText(result!, title: name, newTab: true)
        }
        else {
            queryArea?.switchToMessage()
        }
        queryArea?.addLog(info)
    }

    func onQueryResult(result:[[DBQueryResultItemModel]]?, sql:String, info:String?){
        if result != nil {
            queryArea?.switchToSheet()
            queryArea?.setDataResult(result!)
        }
        else {
            queryArea?.switchToMessage()
        }
        queryArea?.addLog(info)
    }

    func onConnectionError(err: DBConnectionError, info: String?) {
        hideLoading()
        queryArea?.switchToMessage()
        queryArea?.addLog(info)
        showFailurePop("Connection Error", info)
    }
}

///消息和结果页面, 包含切换按钮
fileprivate class QueryArea:BaseViewController{
    var queryResultController : QueryResultController?

    var sqlMessageController : SQLMessageController?

    weak var dbManager:DBConnectionManager?
    
    private let leftViewWidth:CGFloat = 46

    private let leftView = UIView()
    private var resultButton:UIButton?
    private var messageButton:UIButton?
    private var btBgView = UIView()
    
    private var isResult:Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        queryResultController = QueryResultController()
        queryResultController?.delegate = self
        queryResultController?.view.autoresizingMask = [.flexibleHeight, .flexibleTopMargin]
        self.addChild(queryResultController!)
        self.view.addSubview(queryResultController!.view)

        sqlMessageController = SQLMessageController()
        sqlMessageController?.view.autoresizingMask = [.flexibleHeight, .flexibleTopMargin]
        self.addChild(sqlMessageController!)
        self.view.addSubview(sqlMessageController!.view)


        self.view.addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.top.equalToSuperview()
            maker.width.equalTo(leftViewWidth)
            maker.height.equalToSuperview()
        }

        initLeftButtons(leftView)
        let divider = UIView()
        divider.backgroundColor = UIColor.lightGray
        self.view.addSubview(divider)
        divider.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.width.equalTo(0.5)
            maker.left.equalTo(leftView.snp.right)
            maker.bottom.equalToSuperview()
        }

        queryResultController?.view.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.right.equalToSuperview()
            maker.left.equalTo(divider.snp.right)
            maker.bottom.equalToSuperview()
        }

        sqlMessageController?.view.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.right.equalToSuperview()
            maker.left.equalTo(divider.snp.right)
            maker.bottom.equalToSuperview()
        }

        switchToSheet()
    }

    private func initLeftButtons(_ leftView:UIView){

        btBgView.backgroundColor = UIColor.white
        leftView.addSubview(btBgView)

        resultButton = self.makeLeftAreaButton(imageName: "left-datasheet")
        leftView.addSubview(resultButton!)
        messageButton = self.makeLeftAreaButton(imageName: "left-message")
        leftView.addSubview(messageButton!)

        resultButton?.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(50)
        }

        messageButton?.snp.makeConstraints { maker in
            maker.top.equalTo(resultButton!.snp.bottom)
            maker.width.equalToSuperview()
            maker.height.equalTo(50)
        }
    }

    private func makeLeftAreaButton(imageName:String) -> UIButton{
        let button = UIButton(type: .roundedRect)
        button.setImage(UIImage.init(named: imageName), for: .normal)
        button.tintColor = UIColor.darkGray
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets.init(top: 10, left: 12, bottom: 10, right: 12)
        button.addTarget(self, action: #selector(leftAreaButtonAction(_:)), for: .touchUpInside)
        return button
    }

    @objc private func leftAreaButtonAction(_ sender:UIButton){
        if sender == self.resultButton{
            switchToSheet()
        }
        else if sender == self.messageButton{
            switchToMessage()
        }
    }

    func addLog(_ log:String?){
        if log != nil {
            sqlMessageController?.addLog(log!)
        }
    }

    func setDataResult(_ result:[[DBQueryResultItemModel]]){
        self.queryResultController?.data = result
    }

    func switchToSheet(){
        queryResultController?.view.isHidden = false
        sqlMessageController?.view.isHidden = true
        queryResultController?.didMove(toParent: self)
        self.isResult = true
        btBgView.frame = CGRect.init(x: 0, y: 0, width: leftViewWidth, height: 50)
    }
    func switchToMessage(){
        queryResultController?.view.isHidden = true
        sqlMessageController?.view.isHidden = false
        sqlMessageController?.didMove(toParent: self)
        self.isResult = false
        btBgView.frame = CGRect.init(x: 0, y: 50, width: leftViewWidth, height: 50)
    }
    
    override func layoutAllSubviews(_ isWidthCompactLayout: Bool) {
        if self.isResult {
            btBgView.frame = CGRect.init(x: 0, y: 0, width: leftViewWidth, height: 50)
        }else{
            btBgView.frame = CGRect.init(x: 0, y: 50, width: leftViewWidth, height: 50)
        }
    }
}

extension QueryArea : QueryResultDelegate {
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

extension PadMainSplitController:NewConnectionDelegate {
    func onConnect(_ conn: DBConnectionModel) {
        self.connectServer(conn)
    }
}

extension PadMainSplitController : SQLInputDelegate {
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
extension PadMainSplitController {
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
