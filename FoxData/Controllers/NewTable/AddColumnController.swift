//
// 添加/修改某个列
// Created by Zach Wang on 2019-02-28.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit
import PopupDialog

class AddColumnController : BaseViewController {
    
    var column:DBTableColumnPropModel? { // 为nil表示新建
        didSet{
            if column != nil {
                nameField.text = column!.name
                lengthField.text = String(column!.length)
                nullSwitch.isOn = column!.nullable
                primSwitch.isOn = column!.primary
                incSwitch.isOn = column!.autoIncrement
                defaultField.text = column!.defaultValue
                colType = column!.type
                commField.text = column!.comment
            }
        }
    }
    

    private var nameField = UITextField()
    private var lengthField = UITextField()
    private var colType:DBColumnType = .INT
    private var colTypeLabel = UILabel()
    private var incSwitch = UISwitch()
    private var nullSwitch = UISwitch()
    private var primSwitch = UISwitch()
    private var defaultField = UITextField()
    private var commField = UITextField()

    var callback:((_ name:String,
                   _ length:Int,
                   _ nullable:Bool,
                   _ primary:Bool,
                   _ increment:Bool,
                   _ colType:DBColumnType,
                   _ defaultVal:String?,
                   _ commentVal:String?,
                   _ isNew:Bool
                  ) -> Void)?

    var deleteCallback:(()->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let closeButton = self.generateNavBarIconItem(imageName: "back", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton
        let checkButton = self.generateNavBarIconItem(imageName: "check", target: self, action: #selector(saveAction), tintColor: UIColor.red)

        if self.column == nil{
            self.navigationItem.rightBarButtonItem = checkButton
        }
        else {
            let deleteButton = self.generateNavBarIconItem(imageName: "delete", target: self, action: #selector(deleteAction), tintColor: UIColor.red);

            self.navigationItem.rightBarButtonItems = [checkButton, deleteButton]
        }


        let scrollView = UIScrollView.init(frame: self.view.bounds)
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { maker in 
            maker.left.equalToSuperview()
            maker.top.equalToSuperview()
            maker.right.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        let itemHeight:CGFloat = 50;
        var contentHeight:CGFloat = 0

        var line = UIView()
        line.backgroundColor = UIColor.init(white: 0.8, alpha: 1)
        scrollView.addSubview(line)
        line.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.top.equalToSuperview().offset(20)
        }
        contentHeight += 0.5

        // name
        nameField.clearButtonMode = .whileEditing
        nameField.autocapitalizationType = .none
        nameField.autocorrectionType = .no
        nameField.textAlignment = .right
        var view = makeCellView(title: "Name", rightView: nameField, target: self, selector: #selector(nameTapAction))
        scrollView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(itemHeight)
            maker.top.equalTo(line.snp.bottom)
        }

        contentHeight += itemHeight

        line = UIView()
        line.backgroundColor = UIColor.init(white: 0.8, alpha: 1)
        scrollView.addSubview(line)
        line.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.top.equalTo(view.snp.bottom)
        }
        contentHeight += 0.5

        // type
        colTypeLabel.font = UIFont.systemFont(ofSize: 16)
        colTypeLabel.textColor = UIColor.init(white: 0.6, alpha: 1)
        colTypeLabel.textAlignment = .right
        view = makeCellView(title: "Type", rightView: colTypeLabel, target: self, selector: #selector(typeTapAction))
        scrollView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(itemHeight)
            maker.top.equalTo(line.snp.bottom)
        }

        contentHeight += itemHeight

        line = UIView()
        line.backgroundColor = UIColor.init(white: 0.8, alpha: 1)
        scrollView.addSubview(line)
        line.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.top.equalTo(view.snp.bottom)
        }
        contentHeight += 0.5

        // length
        lengthField.clearButtonMode = .whileEditing
        lengthField.textAlignment = .right
        lengthField.keyboardType = .numberPad
        view = makeCellView(title: "Length", rightView: lengthField, target: self, selector: #selector(lengthTapAction))
        scrollView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(itemHeight)
            maker.top.equalTo(line.snp.bottom)
        }

        contentHeight += itemHeight

        line = UIView()
        line.backgroundColor = UIColor.init(white: 0.8, alpha: 1)
        scrollView.addSubview(line)
        line.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.top.equalTo(view.snp.bottom)
        }
        contentHeight += 0.5

        //nullable
        view = makeCellView(title: "Nullable", rightView: nullSwitch, target: nil, selector: nil)
        scrollView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(itemHeight)
            maker.top.equalTo(line.snp.bottom)
        }

        contentHeight += itemHeight

        line = UIView()
        line.backgroundColor = UIColor.init(white: 0.8, alpha: 1)
        scrollView.addSubview(line)
        line.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.top.equalTo(view.snp.bottom)
        }
        contentHeight += 0.5

        //primary
        view = makeCellView(title: "Primary Key", rightView: primSwitch, target: nil, selector: nil)
        scrollView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(itemHeight)
            maker.top.equalTo(line.snp.bottom)
        }

        contentHeight += itemHeight

        line = UIView()
        line.backgroundColor = UIColor.init(white: 0.8, alpha: 1)
        scrollView.addSubview(line)
        line.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.top.equalTo(view.snp.bottom)
        }
        contentHeight += 0.5

        //auto increase
        view = makeCellView(title: "Auto Increment", rightView: incSwitch, target: nil, selector: nil)
        scrollView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(itemHeight)
            maker.top.equalTo(line.snp.bottom)
        }

        contentHeight += itemHeight

        line = UIView()
        line.backgroundColor = UIColor.init(white: 0.8, alpha: 1)
        scrollView.addSubview(line)
        line.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.top.equalTo(view.snp.bottom)
        }
        contentHeight += 0.5

        // default value
        defaultField.clearButtonMode = .whileEditing
        defaultField.textAlignment = .right
        view = makeCellView(title: "Default Value", rightView: defaultField, target: self, selector: #selector(defTapAction))
        scrollView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(itemHeight)
            maker.top.equalTo(line.snp.bottom)
        }

        contentHeight += itemHeight

        line = UIView()
        line.backgroundColor = UIColor.init(white: 0.8, alpha: 1)
        scrollView.addSubview(line)
        line.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.top.equalTo(view.snp.bottom)
        }
        contentHeight += 0.5

        // comment
        commField.clearButtonMode = .whileEditing
        commField.textAlignment = .right
        commField.placeholder = "optional"
        view = makeCellView(title: "Comments", rightView: commField, target: self, selector: #selector(commTapAction))
        scrollView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(itemHeight)
            maker.top.equalTo(line.snp.bottom)
        }

        contentHeight += itemHeight


        scrollView.contentSize = CGSize.init(width: scrollView.contentSize.width, height: contentHeight)

        colTypeLabel.text = colType.rawValue
        if self.column != nil {
            nameField.text = column!.name
            lengthField.text = String(column!.length)
            nullSwitch.isOn = column!.nullable
            primSwitch.isOn = column!.primary
            incSwitch.isOn = column!.autoIncrement
            defaultField.text = column!.defaultValue
            commField.text = column!.comment
        }

    }

    @objc func closeAction(){
        self.navigationController?.popViewController(animated: true)
    }

    @objc func saveAction(){

        if nameField.text == nil || nameField.text == "" {
            showFailurePop("Error", "Please input the name")
            nameField.becomeFirstResponder()
            return
        }

        if (lengthField.text == nil || Int(lengthField.text!) ?? 0 == 0)
            && (colType == .VARCHAR || colType == .DECIMAL || colType == .TINY || colType == .SHORT || colType == .INT || colType == .LONG || colType == .LONGLONG){
            lengthField.becomeFirstResponder()
            showFailurePop("Error", "Please input the length")
            return
        }

        callback?(nameField.text!,
                Int(lengthField.text!) ?? 0,
                nullSwitch.isOn,
                primSwitch.isOn,
                incSwitch.isOn,
                colType,
                defaultField.text,
                commField.text,
                self.column == nil
                )
        self.navigationController?.popViewController(animated: true)
    }

    @objc func deleteAction(){
// Prepare the popup assets
        let title = "Delete"
        let message = "Do you want to delete this column?"

        // Create the dialog
        let popup = PopupDialog(title: title, message: message)

        // Create buttons
        let buttonOne = CancelButton(title: "CANCEL") {

        }

        // This button will not the dismiss the dialog
        let buttonTwo = DestructiveButton(title: "DELETE") {[unowned self] in
            self.deleteCallback?()
            self.navigationController?.popViewController(animated: true)
        }

        // Add buttons to dialog
        // Alternatively, you can use popup.addButton(buttonOne)
        // to add a single button
        popup.addButtons([buttonOne, buttonTwo])

        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }

    @objc func nameTapAction(){
        nameField.becomeFirstResponder()
    }

    @objc func typeTapAction(){
        let contr = SingleSelectViewController()
        //TODO 这里只用了MYSQL的，后续需要兼容多种
        let oriTypes = DBColumnType.getMySQLTypes()
        var data:[String] = []
        for item in oriTypes {
            data.append(item.rawValue)
        }
        let index = oriTypes.firstIndex(of: self.colType)
        if index != nil {
            contr.selectIndex = index!
        }
        contr.data = data
        contr.title = "Select Type"
        contr.callback = { (index) in
            self.colType = oriTypes[index]
            self.colTypeLabel.text = self.colType.rawValue
        }
        self.navigationController?.pushViewController(contr, animated: true)
    }

    @objc func lengthTapAction(){
        lengthField.becomeFirstResponder()
    }

    @objc func defTapAction(){
        defaultField.becomeFirstResponder()
    }

    @objc func commTapAction(){
        commField.becomeFirstResponder()
    }


    func makeCellView(title:String, rightView:UIView?, target:Any?, selector:Selector?) -> UIView{
        var baseView:UIView
        if selector != nil {
            baseView = UIControl()
            (baseView as! UIControl).addTarget(target, action: selector!, for: .touchUpInside)
        }
        else {
            baseView = UIView()
        }
        baseView.backgroundColor = UIColor.white
        let label = UILabel()
        label.text = title
        baseView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(10)
        }

        if rightView != nil{
            baseView.addSubview(rightView!)
            if rightView!.isKind(of: UITextField.self){
                rightView?.snp.makeConstraints { maker in
                    maker.centerY.equalToSuperview()
                    //TODO 宽度有BUG
                    maker.left.equalTo(label.snp.right).offset(10)
                    maker.right.equalToSuperview().offset(-10)
                }
            }else {
                rightView?.snp.makeConstraints { maker in
                    maker.centerY.equalToSuperview()
                    maker.right.equalToSuperview().offset(-10)
                }
            }

        }



        return baseView
    }
}
