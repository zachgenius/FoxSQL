//  表字段
//  AMColumnController.swift
//  FoxData
//
//  Created by Zach Wang on 4/3/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit

class AMColumnController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var columns : [DBTableColumnPropModel]? {
        didSet {
            self.tableView?.reloadData()
        }
    }

    var deletedColumns:[DBTableColumnPropModel] = []
    
    private var tableView:UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView = UITableView.init(frame: self.view.bounds, style: .grouped)
        tableView?.delegate = self
        tableView?.dataSource = self
        self.view.addSubview(tableView!)
        if columns == nil {
            columns = []
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Columns"
        }
        return "Action"
    }


    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows\
        if section == 1 {
            return 1
        }
        if columns == nil || columns?.count == 0{
            return 1
        }
        return columns!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil{
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "cell")
            cell?.accessoryType = .disclosureIndicator
        }

        if indexPath.section == 0 && (columns == nil || columns?.count == 0){
            cell?.textLabel?.text = "EMPTY"
            cell?.detailTextLabel?.text = ""
            return cell!
        }
        
        if indexPath.section == 0 {
            let item = self.columns![indexPath.row]
            cell?.textLabel?.text = item.name
            if item.primary {
                cell?.textLabel?.textColor = UIColor.blue
            }else {
                cell?.textLabel?.textColor = UIColor.black
            }
            let subtitle = NSMutableString()
            
            subtitle.append(item.type.rawValue)
            
            if item.autoIncrement {
                subtitle.append(" INC")
            }
            
            
            if item.nullable {
                subtitle.append(" NUL")
            }
            
            cell?.detailTextLabel?.text = String.init(subtitle)
        }
        else {
            cell?.textLabel?.textColor = UIColor.blue
            cell?.textLabel?.text = "ADD NEW COLUMN"
            cell?.detailTextLabel?.text = ""
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0 && (columns == nil || columns?.count == 0){
            return
        }
        let contr = AddColumnController()
        if indexPath.section == 0 {
            let item = columns![indexPath.row]
            contr.title = item.name
            contr.column = item
        }
        else {
            contr.title = "New Column"
        }

        contr.callback = { [unowned self] (name, length, nullable, primary, increment, colType, defaultValue, commentValue, isNew) in
            if isNew {
                let col = DBTableColumnPropModel()
                col.name = name
                col.type = colType
                col.length = Int32(length)
                col.nullable = nullable
                col.primary = primary
                col.autoIncrement = increment
                col.defaultValue = defaultValue
                col.comment = commentValue
                self.columns?.append(col)
            }
            else {
                let col = self.columns![indexPath.row]
                col.name = name
                col.type = colType
                col.length = Int32(length)
                col.nullable = nullable
                col.primary = primary
                col.autoIncrement = increment
                col.defaultValue = defaultValue
                col.comment = commentValue
                self.columns?.replaceSubrange(Range.init(NSRange.init(location: indexPath.row, length: 1))!, with: [col])
            }

            self.tableView?.reloadData()
        }

        contr.deleteCallback = {[unowned self] () in
            let item = self.columns?.remove(at: indexPath.row)

            if item != nil {
                self.deletedColumns.append(item!)
            }
        }

        self.navigationController?.pushViewController(contr, animated: true)
    }

}
