// Views列表
// Created by Zach Wang on 2019-04-09.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

class LSLViewsController : UIViewController {

    weak var parentController : LeftSelectController?

    func loadSectionKeys(_ db:DBDatabaseModel?){
        var keys:[String] = []
        var values:[String:[String]] = [:]
        if db?.views != nil {
            for (key, value) in db!.tables! {
                keys.append(key)
                values[key] = value
            }
        }
        self.sectionKeys = keys
        self.sectionItemKeys = values
    }

    /// 列表每项标题. 只保存 table/view/procedure的key, 其他的都单独处理
    private var sectionKeys:[String] = []

    /// key: sectionKey, value: [item]. table/view/procedure的每一项的标题
    private var sectionItemKeys:[String:[String]] = [:]

    var tableView: UITableView?

    var currentDB: DBDatabaseModel? = nil{
        didSet {
            self.loadSectionKeys(currentDB)
            self.tableView?.stopPullToRefresh()
            self.tableView?.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.register(OpeningDBListCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(tableView!)
        tableView?.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.top.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalToSuperview()
        }

        tableView?.addPullToRefreshWithAction({[unowned self] in
            if self.currentDB == nil{
                self.tableView?.stopPullToRefresh()
                return
            }
            self.parentController?.reqDelegate?.lslRequestViews(self.currentDB!.name)
        })

    }
}

extension LSLViewsController : UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! OpeningDBListCell
        cell.indexPath = indexPath
        cell.menuButton.isHidden = true
        cell.delegate = self
        if currentDB == nil{
            cell.textLabel?.text = "EMPTY"
        }

        else if currentDB?.views == nil{
            cell.textLabel?.text = "Loading"
        }
        else {
            let key = sectionKeys[indexPath.section - 1]
            if sectionItemKeys[key]!.count == 0 {
                cell.textLabel?.text = "EMPTY"
            }
            else {
                cell.textLabel?.text = sectionItemKeys[key]![indexPath.row]
                cell.menuButton.isHidden = false
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{ // 只留给标题
            return 0
        }
        var counts = 0
        if currentDB?.views != nil {
            let key = sectionKeys[section - 1]
            counts = sectionItemKeys[key]!.count
        }

        if counts == 0{
            counts = 1 // 用来显示状态, 比如正在获取或者无数据
        }
        return counts
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if sectionKeys.count > 0 {
            let key = sectionKeys[indexPath.section - 1]
            if sectionItemKeys[key]!.count == 0 {
                return
            }
            let item = sectionItemKeys[key]![indexPath.row]
            parentController?.reqDelegate?.lslSendSql(sendSql: "SELECT * FROM " + item + " LIMIT 100;", db: currentDB!.name, run: true, newTab: true)
        }
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        var numbers = 1 + sectionKeys.count
        if numbers == 1{
            numbers = 2
        }
        return numbers
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return "Views"
        }

        if sectionKeys.count == 0 {
            return "All"
        }

        return sectionKeys[section - 1]
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}

extension LSLViewsController:OpeningDBListCellDelegate{
    func onMenuClick(_ anchorView:UIView, _ indexPath: IndexPath) {
        guard let list = currentDB?.views else {
            return
        }

        FTPopOverMenu.showForSender(sender: anchorView,
                with: [
                    "Top 100 rows",
                    "View create statement",
                    "Drop view",
                ],
                done: { [unowned self](index) in
                    let key = self.sectionKeys[indexPath.section - 1]
                    let item = list[key]![indexPath.row]
                    let db = self.currentDB!.name
                    switch index {
                    case 0:// top 100 rows
                        self.parentController?.reqDelegate?.lslSendSql(sendSql: "SELECT * FROM " + item + " LIMIT 100;", db: db, run: true, newTab: true)
                        break
                    case 1: // view create statement
                        self.parentController?.reqDelegate?.lslShowCreate(.view, db: db, toShow: item)
                        break
                    case 2: // drop view
                        self.parentController?.reqDelegate?.lslShowDangerProcessAlert("Drop View", hint:"Are you sure to remove the view?", sql: "DROP VIEW " + item + ";", db: db)
                        break
                    default:

                        break
                    }

                }) {

        }

    }
}
