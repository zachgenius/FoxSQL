//
// 新建/修改连接界面
// Created by Zach Wang on 2019-01-18.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

import PopupDialog

class InputConnectionController: BaseViewController {
    var model:DBConnectionModel = DBConnectionModel()
    weak var delegate:InputConnectionDelegate?
    var isNew:Bool = false

    private var tableView:UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initTitles()
        
        tableView = UITableView.init(frame: CGRect.zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview()
            maker.top.equalToSuperview()
            maker.right.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

    }

    private func initTitles(){
        let closeButton = self.generateNavBarIconItem(imageName: "back", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton
        let checkButton = self.generateNavBarIconItem(imageName: "check", target: self, action: #selector(checkAction), tintColor: UIColor.red)
        
        
        if isNew {
            if model.type == .MySQL{
                self.title = "MySQL"
            }
            self.navigationItem.rightBarButtonItem = checkButton
        }else {
            if !model.alias.isEmpty {
                self.title = model.alias
            }else{
                self.title = model.host
            }
            let deleteButton = self.generateNavBarIconItem(imageName: "delete", target: self, action: #selector(deleteConnAction), tintColor: UIColor.red);
            
            self.navigationItem.rightBarButtonItems = [checkButton, deleteButton]
        }
    }


    @objc func closeAction(){
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func deleteConnAction(){
        // Prepare the popup assets
        let title = "Delete server"
        let message = "Do you want to delete this server?"
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message)
        
        // Create buttons
        let buttonOne = CancelButton(title: "CANCEL") {
            
        }
        
        // This button will not the dismiss the dialog
        let buttonTwo = DestructiveButton(title: "DELETE") {[unowned self] in
            self.delegate?.onDelete(self.model)
            self.navigationController?.popViewController(animated: true)
        }

        // Add buttons to dialog
        // Alternatively, you can use popup.addButton(buttonOne)
        // to add a single button
        popup.addButtons([buttonOne, buttonTwo])
        
        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    @objc func checkAction(){
        self.view.endEditing(true)
        let host = model.host
        let username  = model.username
        let port = model.port
        
        guard host != "" else {
            showFailurePop("Failed", "Please input the host or ip of the server")
            return
        }
       
        if port <= 0 || port > 65535 {
            showFailurePop("Failed", "Port number error")
            return
        }
        
        guard username != "" else {
            showFailurePop("Failed", "Please input the username of the server")
            return
        }
        
        if model.isSSH {
            if model.sshHost == "" {
                showFailurePop("Failed", "Please input the ssh host or ip of the server")
                return
            }
            
            if model.sshUser == "" {
                showFailurePop("Failed", "Please input the ssh username of the server")
                return
            }
            
            if model.sshPort <= 0 || model.sshPort > 65535 {
                showFailurePop("Failed", "SSH port number error")
                return
            }
        }
        
        if isNew {
            model.id = UUID().uuidString
            model.createTime = Int(Date().timeIntervalSince1970)
        }
        
        self.delegate?.onSave(model, isNew)
        self.navigationController?.popViewController(animated: true)
    }

    private func openInputSSHKeyAction(){
        
        let contr = InputSSHKeyController()
        contr.pubKey = model.sshPubKey
        contr.privKey = model.sshPrivKey
        contr.privKeyPwd = model.sshPrivPasswordPhrase
        contr.callback = { [unowned self](pubKey, privKey, pwd) in
            self.model.sshPubKey = pubKey
            self.model.sshPrivKey = privKey
            self.model.sshPrivPasswordPhrase = pwd
            self.tableView.reloadData()
        }
        self.navigationController?.pushViewController(contr, animated: true)
    }
    
    private func charsetAction(){
        do {
            let jsonUrl = Bundle.main.url(forResource: "MysqlCharset", withExtension: "json")
            let jsonDecoder = JSONDecoder()
            let jsonData = try Data(contentsOf: jsonUrl!)
            let jsonRoot = try jsonDecoder.decode(CharsetStruct.self, from: jsonData) as CharsetStruct
            let charsets = jsonRoot.charset
            let index = charsets.firstIndex(of: self.model.charset)
            let controller = SingleSelectViewController()
            controller.data = charsets
            controller.title = "Charsets"
            if index != nil {
                controller.selectIndex = index!
            }
            controller.callback = {[unowned self] (index) in
                self.model.charset = charsets[index]
                self.tableView.reloadData()
            }
            self.navigationController?.pushViewController(controller, animated: true)
        }
        catch {
            print(error)
        }
       
    }
}

extension InputConnectionController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 6
        }
        
        if !model.isSSH {
            return 2
        }
        
        if !model.sshIsKey {
            return 7
        }
        
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // general
        if indexPath.section == 0 {
            var cell : RightInputTableCell? = tableView.dequeueReusableCell(withIdentifier: "input") as? RightInputTableCell
            if cell == nil{
                cell = RightInputTableCell.init(style: .default, reuseIdentifier: "input")
                cell?.rightInput?.delegate = self
            }
            cell?.rightInput?.keyboardType = .alphabet
            cell?.rightInput?.isSecureTextEntry = false
            cell?.rightInput?.placeholder = "required"
            cell?.rightInput?.isEnabled = true
            switch indexPath.row {
            case 0: // host
                cell?.textLabel?.text = "Host / IP"
                cell?.rightInput?.text = model.host
                break
                
            case 1: // port
                cell?.textLabel?.text = "Port"
                cell?.rightInput?.text = "\(model.port)"
                cell?.rightInput?.keyboardType = .numberPad
                break
                
            case 2: // Username
                cell?.textLabel?.text = "Username"
                cell?.rightInput?.text = model.username
                break
            case 3: // Password
                cell?.textLabel?.text = "Password"
                cell?.rightInput?.placeholder = "optional"
                cell?.rightInput?.text = model.password
                cell?.rightInput?.isSecureTextEntry = true
                break
            case 4: // Database
                cell?.textLabel?.text = "Database"
                cell?.rightInput?.placeholder = "optional"
                cell?.rightInput?.text = model.db
                break
            case 5: // Alias
                cell?.textLabel?.text = "Alias"
                cell?.rightInput?.placeholder = "optional"
                cell?.rightInput?.text = model.alias
                break
                
            default:
                break
            }
            cell?.rightInput?.tag = indexPath.row
            return cell!
            
        }
        //advanced
        else {
            var cell : UITableViewCell? = nil
            
            switch indexPath.row {
            case 0:// charset
                let theCell = UITableViewCell.init(style: .value1, reuseIdentifier: "normal")
                theCell.textLabel?.text = "Charset"
                theCell.detailTextLabel?.text = model.charset
                theCell.accessoryType = .disclosureIndicator
                cell = theCell
                break
                
            case 1:// over ssh switch
                var theCell = tableView.dequeueReusableCell(withIdentifier: "switch") as? RightSwitchTableCell
                if theCell == nil{
                    theCell = RightSwitchTableCell.init(style: .default, reuseIdentifier: "switch")
                }
                theCell?.textLabel?.text = "Over SSH"
                theCell?.rightSwitch.isOn = model.isSSH
                theCell?.rightSwitch.tag = 11
                theCell?.rightSwitch.addTarget(self, action: #selector(onSwitchChanged(_:)), for: .valueChanged)
                cell = theCell
                break
                
            case 2: // ssh host
                var theCell : RightInputTableCell? = tableView.dequeueReusableCell(withIdentifier: "input") as? RightInputTableCell
                if theCell == nil{
                    theCell = RightInputTableCell.init(style: .default, reuseIdentifier: "input")
                    theCell?.rightInput?.delegate = self
                }
                theCell?.textLabel?.text = "SSH Host"
                theCell?.rightInput?.text = model.sshHost
                theCell?.rightInput?.tag = 12
                theCell?.rightInput?.delegate = self
                theCell?.rightInput?.keyboardType = .alphabet
                theCell?.rightInput?.isSecureTextEntry = false
                theCell?.rightInput?.placeholder = "required"
                theCell?.rightInput?.isEnabled = true
                cell = theCell
                break
            case 3: // ssh port
                var theCell : RightInputTableCell? = tableView.dequeueReusableCell(withIdentifier: "input") as? RightInputTableCell
                if theCell == nil{
                    theCell = RightInputTableCell.init(style: .default, reuseIdentifier: "input")
                    theCell?.rightInput?.delegate = self
                }
                theCell?.textLabel?.text = "SSH Port"
                theCell?.rightInput?.text = "\(model.sshPort)"
                theCell?.rightInput?.tag = 13
                theCell?.rightInput?.delegate = self
                theCell?.rightInput?.keyboardType = .numberPad
                theCell?.rightInput?.isSecureTextEntry = false
                theCell?.rightInput?.placeholder = "required"
                theCell?.rightInput?.isEnabled = true
                cell = theCell
                break
            case 4: // ssh username
                var theCell : RightInputTableCell? = tableView.dequeueReusableCell(withIdentifier: "input") as? RightInputTableCell
                if theCell == nil{
                    theCell = RightInputTableCell.init(style: .default, reuseIdentifier: "input")
                    theCell?.rightInput?.delegate = self
                }
                theCell?.textLabel?.text = "SSH Username"
                theCell?.rightInput?.text = model.sshUser
                theCell?.rightInput?.tag = 14
                theCell?.rightInput?.delegate = self
                theCell?.rightInput?.keyboardType = .alphabet
                theCell?.rightInput?.isSecureTextEntry = false
                theCell?.rightInput?.placeholder = "required"
                theCell?.rightInput?.isEnabled = true
                cell = theCell
                break
            case 5: // ssh password
                var theCell : RightInputTableCell? = tableView.dequeueReusableCell(withIdentifier: "input") as? RightInputTableCell
                if theCell == nil{
                    theCell = RightInputTableCell.init(style: .default, reuseIdentifier: "input")
                    theCell?.rightInput?.delegate = self
                }
                theCell?.textLabel?.text = "SSH Password"
                theCell?.rightInput?.text = model.sshPassword
                theCell?.rightInput?.tag = 15
                theCell?.rightInput?.delegate = self
                theCell?.rightInput?.keyboardType = .alphabet
                theCell?.rightInput?.isSecureTextEntry = true
                theCell?.rightInput?.placeholder = "optional"
                
                theCell?.rightInput?.isEnabled = !model.sshIsKey
                
                cell = theCell
                break
                
            case 6:// pub key
                var theCell = tableView.dequeueReusableCell(withIdentifier: "switch") as? RightSwitchTableCell
                if theCell == nil{
                    theCell = RightSwitchTableCell.init(style: .default, reuseIdentifier: "switch")
                }
                theCell?.textLabel?.text = "Use Public Key"
                theCell?.rightSwitch.isOn = model.sshIsKey
                theCell?.rightSwitch.tag = 16
                theCell?.rightSwitch.addTarget(self, action: #selector(onSwitchChanged(_:)), for: .valueChanged)
                cell = theCell
                break
                
            case 7:// SSH Key
                let theCell = UITableViewCell.init(style: .value1, reuseIdentifier: "normal")
                theCell.textLabel?.text = "SSK Key"
                if model.sshPubKey == ""{
                    theCell.detailTextLabel?.text = "(empty)"
                }else {
                    theCell.detailTextLabel?.text = "(key set)"
                }
                
                theCell.accessoryType = .disclosureIndicator
                cell = theCell
                break
                
            default:
                break
            }
            
            return cell!
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "General"
        }
        
        return "Advanced"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 1 && indexPath.row == 0 {
            charsetAction()
        } else if indexPath.section == 1 && indexPath.row == 7 {
            openInputSSHKeyAction()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
}

extension InputConnectionController : UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField.tag {
        case 0:// host
            model.host = textField.text!
            break
        case 1:// port
            model.port = UInt32(textField.text ?? "0") ?? 0
            break
        case 2:// user
            model.username = textField.text!
            break
        case 3:// password
            model.password = textField.text!
            break
        case 4:// database
            model.db = textField.text!
            break
        case 5:// alias
            model.alias = textField.text!
            break
            
        case 12:// ssh host
            model.sshHost = textField.text!
            break
            
        case 13:// ssh port
            model.sshPort = Int(textField.text!) ?? 22
            break
            
        case 14:// ssh user
            model.sshUser = textField.text!
            break
            
        case 15:// ssh pass
            model.sshPassword = textField.text!
            break
            
        default:
            break
        }
    }
    
    @objc private func onSwitchChanged(_ sender:UISwitch){
        let value = sender.isOn
        if sender.tag == 11 { // over ssh
            model.isSSH = value
        } else if sender.tag == 16 { // is pub key
            model.sshIsKey = value
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {[unowned self] in
            self.tableView.reloadData()
        }

    }
}

protocol InputConnectionDelegate : class {
    func onSave(_ conn:DBConnectionModel, _ isNew:Bool)
    func onDelete(_ conn:DBConnectionModel)
}

