// 确定新添加表
// Created by Zach Wang on 2019-04-09.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

class ConfirmAddTableController : BaseViewController, UITableViewDataSource, UITableViewDelegate{
    var callback:((_ name:String, _ charset:String, _ charCollation:String, _ engine:String)->Void)?

    private var tableView:UITableView?

    private var nameInput:UITextField?

    private var charsets:[String] = []
    private var collations:[String:[String]] = [:]
    private var engines:[String] = []

    private var selectedCharset = ""
    private var selectedCollation = ""
    private var selectedEngine = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Table Details"

        let closeButton = self.generateNavBarIconItem(imageName: "back", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton
        let checkButton = self.generateNavBarIconItem(imageName: "check", target: self, action: #selector(saveAction), tintColor: UIColor.red)
        self.navigationItem.rightBarButtonItem = checkButton

        tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView?.delegate = self
        tableView?.dataSource = self
        self.view.addSubview(tableView!)
        tableView?.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.top.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalToSuperview()
        }

        loadCharsets()
    }

    @objc func closeAction(){
        self.navigationController?.popViewController(animated: true)
    }

    @objc func saveAction(){
        let name = self.nameInput!.text!
        if name == ""{
            nameInput?.becomeFirstResponder()
            showFailurePop("name", "Please input the table name")
            return
        }
        self.callback?(name, selectedCharset, selectedCollation, selectedEngine)
        self.navigationController?.popViewController(animated: true)
    }

    private func loadCharsets(){
        do {
            let jsonUrl = Bundle.main.url(forResource: "MysqlCharset", withExtension: "json")
            let jsonDecoder = JSONDecoder()
            let jsonData = try Data(contentsOf: jsonUrl!)
            let jsonRoot = try jsonDecoder.decode(CharsetStruct.self, from: jsonData) as CharsetStruct

            self.charsets.append(contentsOf: jsonRoot.charset)

            self.collations = jsonRoot.collation

            self.engines.append(contentsOf: jsonRoot.engine)

            self.selectedCharset = "utf8mb4"
            self.selectedCollation = self.collations[self.selectedCharset]![0]
            self.selectedEngine = self.engines[0]
            tableView?.reloadData()
            
        }
        catch {
            print(error)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 1
        }

        return 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return "General"
        }

        return "Extra"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            var cell:RightInputTableCell? = tableView.dequeueReusableCell(withIdentifier: "general") as? RightInputTableCell
            if cell == nil {
                cell = RightInputTableCell.init(style: .default, reuseIdentifier: "general")
                self.nameInput = cell?.rightInput
            }
            cell?.textLabel?.text = "Table Name"
            cell?.rightInput?.placeholder = "name"
            return cell!
        }
        else {
            var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "extra")
            if cell == nil {
                cell = UITableViewCell.init(style: .value1, reuseIdentifier: "extra")
                cell?.detailTextLabel?.textColor = UIColor.gray
                cell?.accessoryType = .disclosureIndicator
            }
            if indexPath.row == 0 {
                cell?.textLabel?.text = "Charset"
                cell?.detailTextLabel?.text = self.selectedCharset
            } else if indexPath.row == 1 {
                cell?.textLabel?.text = "Collation"
                cell?.detailTextLabel?.text = self.selectedCollation
            } else if indexPath.row == 2 {
                cell?.textLabel?.text = "Engine"
                cell?.detailTextLabel?.text = self.selectedEngine
            }
            return cell!
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {

        //第一个带输入框，不需要选中
        if indexPath.row == 0 && indexPath.section == 0 {
            return nil
        }

        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        let contr = SingleSelectViewController()
        //charset
        if indexPath.row == 0{
            contr.title = "Charset"
            contr.data = self.charsets
            contr.callback = { [unowned self](index) in
                self.selectedCharset = self.charsets[index]
                self.selectedCollation = self.collations[self.selectedCharset]![0]
                self.tableView?.reloadData()
            }
            contr.selectIndex = self.charsets.firstIndex(of: self.selectedCharset)!
        }
        // collation
        else if indexPath.row == 1{
            contr.title = "Collation"
            contr.data = self.collations[self.selectedCharset]!
            contr.callback = { (index) in
                self.selectedCollation = self.collations[self.selectedCharset]![index]
                self.tableView?.reloadData()
            }
            contr.selectIndex = self.collations[self.selectedCharset]!.firstIndex(of: self.selectedCollation)!
        }
        //engine
        else {
            contr.title = "Engine"
            contr.data = self.engines
            contr.callback = { [unowned self](index) in
                self.selectedEngine = self.engines[index]
                self.tableView?.reloadData()
            }
            contr.selectIndex = self.engines.firstIndex(of: self.selectedEngine)!
        }
        
        self.navigationController?.pushViewController(contr, animated: true)
    }
}
