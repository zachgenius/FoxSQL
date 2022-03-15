//  表索引
//  AMIndexController.swift
//  FoxData
//
//  Created by Zach Wang on 4/5/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit

class AMIndexController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var indexes: [DBTableIndexPropModel]? {
        didSet {
            self.tableView?.reloadData()
        }
    }

    private var tableView:UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView = UITableView.init(frame: self.view.bounds, style: .grouped)
        tableView?.delegate = self
        tableView?.dataSource = self
        self.view.addSubview(tableView!)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Indexes"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if indexes == nil {
            return 0
        }
        return indexes!.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil{
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "cell")
        }

        let item = self.indexes![indexPath.row]
        cell?.textLabel?.text = item.name


        return cell!
    }

}
