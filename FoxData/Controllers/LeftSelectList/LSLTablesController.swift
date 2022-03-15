// 表列表
// Created by Zach Wang on 2019-04-09.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

class LSLTablesController : BaseViewController {

    weak var parentController : LeftSelectController?

    func loadSectionKeys(_ db:DBDatabaseModel?){
        var keys:[String] = []
        var values:[String:[String]] = [:]
        if db?.tables != nil {
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
            self.parentController?.reqDelegate?.lslRequestTables(self.currentDB!.name)
        })

    }
}

extension LSLTablesController : UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! OpeningDBListCell
        cell.indexPath = indexPath
        cell.menuButton.isHidden = true
        cell.delegate = self

        if currentDB?.tables != nil && indexPath.section == 1 {
            // new table
            cell.textLabel?.text = "New Table"
            return cell
        }

        if currentDB == nil{
            cell.textLabel?.text = "EMPTY"
        }

        else if currentDB?.tables == nil{
            cell.textLabel?.text = "Loading"
        }
        else {

            let key = sectionKeys[indexPath.section - 2]

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
        if currentDB?.tables != nil && section > 1 {
            let key = sectionKeys[section - 2]

            counts = sectionItemKeys[key]!.count
        }

        if counts == 0{
            counts = 1 // 用来显示状态, 比如正在获取或者无数据
        }
        return counts
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        guard let list = currentDB?.tables else {
            return
        }

        if indexPath.section == 0 {
            return
        }
        if indexPath.section == 1 { // new table

            parentController?.reqDelegate?.lslNewTable(currentDB!.name)
            return
        }

        if list.count > 0 {
            let key = sectionKeys[indexPath.section - 2]
            if sectionItemKeys[key]!.count == 0 {
                return
            }
            let item = list[key]![indexPath.row]
            parentController?.reqDelegate?.lslSendSql(sendSql: "SELECT * FROM " + item + " LIMIT 100;", db: currentDB!.name, run: true, newTab: true)
        }
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        if currentDB?.tables == nil{
            return 2
        }
        else {
            return 2 + sectionKeys.count
        }

    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return "Tables"
        }
        if section == 1 {
            if (currentDB?.tables != nil) {
                // new table
                return "Action"
            }
            else {
                // empty
                return "All"
            }

        }

        return sectionKeys[section - 2]
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

extension LSLTablesController:OpeningDBListCellDelegate{
    func onMenuClick(_ anchorView:UIView, _ indexPath: IndexPath) {
        guard let list = currentDB?.tables else {
            return
        }


        FTPopOverMenu.showForSender(sender: anchorView,
                with: [
                    "Top 100 rows",
                    "View create statement",
                    //            "Alter table",
                    //            "Insert data",
                    "Drop table",
                    "Truncate table"
                ],
                done: { (selectedIndex) -> () in

                    let key = self.sectionKeys[indexPath.section - 2]
                    let item = list[key]![indexPath.row]
                    let db = self.currentDB!.name
                    switch selectedIndex {
                    case 0:// top 100 rows
                        self.parentController?.reqDelegate?.lslSendSql(sendSql: "SELECT * FROM " + item + " LIMIT 100;", db: db, run: true, newTab: true)
                        break
                    case 1: // view create statement
                        self.parentController?.reqDelegate?.lslShowCreate(.table, db: db, toShow: item)
                        break
                            //todo 暂时放到下一版
                            //            case 2: // alter table
                            //                self.openingDBListController?.delegate?.openingDBListAlterTable(item, db: db)
                            //                break
                            //            case 3: // insert data
//                    self.openingDBListController?.delegate?.openingDBListInsertData(item, db: db)
//                    break
                    case 2: // drop table
                        self.parentController?.reqDelegate?.lslShowDangerProcessAlert("Drop Table", hint:"Are you sure to remove the table?", sql: "DROP TABLE " + item + ";", db: db)
                        break
                    case 3:// truncate table
                        self.parentController?.reqDelegate?.lslShowDangerProcessAlert("Truncate Table", hint:"Are you sure to remove all contents from the table?", sql: "DELETE FROM " + item + ";", db: db)
                        break
                    default:

                        break
                    }
                }) {

        }
    }
}
