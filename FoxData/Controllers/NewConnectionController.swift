//
// 新建连接
// Created by Zach Wang on 2019-01-22.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit
import UIColor_Hex_Swift

class NewConnectionController : BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {

    weak var delegate:NewConnectionDelegate?
    private var serverList:UITableView?
    private lazy var newDBPanel = DBTypeCollectionView()

    private let dbQueryQueue = DispatchQueue(label: "mysqlConn", qos: .background)

    let availableDB = [DBType.MySQL] //[DBType.MySQL, DBType.PostgreSQL]
    
    var savedServers:[DBConnectionModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        let closeButton = self.generateNavBarIconItem(imageName: "close", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton
        
        // settings
        let settingButton = self.generateNavBarIconItem(imageName: "setting", target: self, action: #selector(settingItemAction))
        self.navigationItem.rightBarButtonItem = settingButton

        self.title = "New Connection"

        newDBPanel.initViews()
        newDBPanel.collectionView?.delegate = self
        newDBPanel.collectionView?.dataSource = self
        self.view.addSubview(newDBPanel)

        serverList = UITableView(frame: CGRect.zero, style: .grouped)
        serverList!.delegate = self
        serverList!.dataSource = self
        self.view.addSubview(serverList!)

        newDBPanel.panelLayout.scrollDirection = .horizontal

        var topMargin:CGFloat? = self.navigationController?.navigationBar.frame.height
        if topMargin == nil{
            topMargin = 0
        }

        newDBPanel.snp.remakeConstraints { maker in
            maker.top.equalToSuperview().offset(topMargin!)
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(200)
        }
        serverList!.snp.remakeConstraints { maker in
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.top.equalTo(newDBPanel.snp.bottom).offset(4)

            if #available(iOS 11, *) {
                maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottomMargin)
            } else {
                maker.bottom.equalToSuperview()
            }
        }
        newDBPanel.collectionView?.reloadData()
        reloadDBs()
    }

    @objc func closeAction(){
        self.dismiss(animated: true)
    }
    
    @objc func settingItemAction(){
        let nav = UINavigationController.init(rootViewController: SettingsController())
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    private func reloadDBs(){
        dbQueryQueue.async {[unowned self] in
            self.savedServers = LocalDBManager.get().getAllDB()
            __dispatch_async(.main) {[unowned self] in
                self.serverList!.reloadData()
            }
        }
    }
    
    private func tryAuthAndDismiss(_ conn:DBConnectionModel){
        showLoading()
        if conn.type == .MySQL {
            DBConnectionMySQL.checkAuth(conn) { [unowned self](code, msg) in
                self.hideLoading()
                if code == 0{
                    self.delegate?.onConnect(conn)
                    self.dismiss(animated: true, completion: nil)
                }
                else {
                    self.showFailurePop("Authentication Failed", msg)
                }
            }
        }
        else if conn.type == .PostgreSQL {
            DBConnectionPostgreSQL.checkAuth(conn) { [unowned self](code, msg) in
                self.hideLoading()
                if code == 0{
                    self.delegate?.onConnect(conn)
                    self.dismiss(animated: true, completion: nil)
                }
                else {
                    self.showFailurePop("Authentication Failed", msg)
                }
            }
        }
    }

    // MARK: - Collection Delegate Datasource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableDB.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let view :DBPanelItemView = collectionView.dequeueReusableCell(withReuseIdentifier: "DBType", for: indexPath) as! DBPanelItemView

        view.initViews(type: availableDB[indexPath.row])
        return view
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellWidth : CGFloat = 150.0

        let numberOfCells: CGFloat = CGFloat(availableDB.count)
        var edgeInsets = (collectionView.frame.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)

        if edgeInsets < 0 {
            edgeInsets = 0
        }

        return UIEdgeInsets(top: 0, left: edgeInsets, bottom: 0, right: edgeInsets)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let item = availableDB[indexPath.row]
        let controller = InputConnectionController.init()
        controller.delegate = self
        controller.isNew = true
        let model = DBConnectionModel(type:item)
        controller.model = model
        self.navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - Table Delegate Datasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            var count = savedServers.count
            if count == 0 {
                count += 1
            }

            return count
        }

        // one sample server
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        //no data
        if indexPath.section == 0 && savedServers.isEmpty {
            var cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell")
            if cell == nil {
                cell = UITableViewCell.init()
            }
            cell?.textLabel?.text = "EMPTY"
            return cell!
        }

        let reuseIdentifier = "UnPlugin"
        var cell:ConnectionItemCell? = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ConnectionItemCell
        if cell == nil {
            cell = ConnectionItemCell.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }
        cell!.indexPath = indexPath
        cell!.delegate = self

        // saved
        if indexPath.section == 0 {
            cell!.menuButton.isHidden = false
            let item = savedServers[indexPath.row]
            if (item.type == .MySQL){
                cell!.imageView?.image = UIImage(named: "icon_mysql")
            }
            else if item.type == .PostgreSQL {
                cell!.imageView?.image = UIImage(named: "icon_postgres")
            }
            if item.alias.isEmpty {
                cell!.textLabel?.text = item.username + "@" + item.host + ":\(item.port)"
                cell!.detailTextLabel?.text = ""
            }
            else{
                cell!.textLabel?.text = item.alias
                cell!.detailTextLabel?.text = item.username + "@" + item.host + ":\(item.port)"
            }
        }
        else {
            cell!.imageView?.image = UIImage(named: "icon_mysql")
            cell!.menuButton.isHidden = true
            cell!.textLabel?.text = "Vulpes"
            cell?.detailTextLabel?.text = "sample user"
        }
        
        
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if indexPath.section == 0 && savedServers.isEmpty{
            return
        }

        var item:DBConnectionModel
        if indexPath.section == 0 {
            item = savedServers[indexPath.row]

        }
        else {
            item = DBConnectionModel()
            item.host = "128.199.64.197"
            item.username = "foxtest"
            item.password = "DaKioSC1Q2AbpGe0"
            item.db = "Vulpes"
            item.isSample = true
        }
        tryAuthAndDismiss(item)

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 as CGFloat
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == serverList {
            let sectionHeaderHeight = 5 as CGFloat
            if (scrollView.contentOffset.y <= sectionHeaderHeight && scrollView.contentOffset.y >= 0) {
                scrollView.contentInset = UIEdgeInsets(top: -scrollView.contentOffset.y, left: 0, bottom: 0, right: 0)
            } else if (scrollView.contentOffset.y >= sectionHeaderHeight) {
                scrollView.contentInset = UIEdgeInsets(top: -sectionHeaderHeight, left: 0, bottom: 0, right: 0)
            }

        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Sample Servers"
        }

        return "Saved Servers"
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
}

protocol NewConnectionDelegate:class {
    func onConnect(_ conn:DBConnectionModel)
}

extension NewConnectionController : InputConnectionDelegate{
    func onDelete(_ conn: DBConnectionModel) {
        LocalDBManager.get().deleteDB(conn.id)
        savedServers = LocalDBManager.get().getAllDB()
        serverList!.reloadData()
    }
    
    func onSave(_ conn: DBConnectionModel, _ isNew: Bool) {
        LocalDBManager.get().saveDB(conn)
        savedServers = LocalDBManager.get().getAllDB()
        serverList!.reloadData()
        if isNew {
            tryAuthAndDismiss(conn)
        }
        
    }
}

extension NewConnectionController:ConnectionItemCellDelegate{
    func onMenuClick(_ anchorView: UIView, _ indexPath: IndexPath) {
        let item = savedServers[indexPath.row]
        let controller = InputConnectionController.init()
        controller.delegate = self
        controller.isNew = false
        controller.model = item
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
