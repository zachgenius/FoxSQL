//
//  SingleSelectViewController.swift
//  FoxData
//
//  Created by Zach Wang on 4/1/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit

class SingleSelectViewController: UITableViewController {

    var data:[String] = []
    var selectIndex = -1
    
    var callback:((_ index:Int) -> Void)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        let closeButton = self.generateNavBarIconItem(imageName: "back", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton
    }
    
    @objc func closeAction(){
        self.navigationController?.popViewController(animated: true);
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return data.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = data[indexPath.row]
        if self.selectIndex == indexPath.row {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        selectIndex = indexPath.row
        tableView.reloadData()
        callback?(selectIndex)
        self.closeAction()
    }
}
