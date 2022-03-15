// db列表
// Created by Zach Wang on 2019-04-09.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

class LSLDatabasesController : UIViewController {

    var tableView: UITableView?

    weak var parentController : LeftSelectController?

    var totalDBs: [String]? = nil{
        didSet {
            self.tableView?.stopPullToRefresh()
            self.tableView?.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(tableView!)
        tableView?.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.top.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalToSuperview()
        }

        tableView?.addPullToRefreshWithAction({[unowned self] in
            if self.totalDBs == nil{
                self.tableView?.stopPullToRefresh()
                return
            }
            self.parentController?.reqDelegate?.lslRequestLoadAllDatabases()
        })


    }
}

extension LSLDatabasesController :UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        if totalDBs == nil{
            cell.textLabel?.text = "Loading"
        }
        else {
            if totalDBs!.count == 0 {
                cell.textLabel?.text = "EMPTY"
            }
            else {
                cell.textLabel?.text = totalDBs![indexPath.row]
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{ // 只留给标题
            return 0
        }
        var counts = 0
        if totalDBs != nil{
            counts = totalDBs!.count
        }

        if counts == 0{
            counts = 1 // 用来显示状态, 比如正在获取或者无数据
        }
        return counts
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        guard let list = totalDBs else {
            return
        }
        if list.count > 0 {
            let db = list[indexPath.row]
            self.parentController?.reqDelegate?.lslSwitchDB(switchDB: db)
        }
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return "Databases"
        }

        return "All"
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


