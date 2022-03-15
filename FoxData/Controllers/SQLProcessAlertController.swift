//
// 提示即将执行xxx的controller
//
// Created by Zach Wang on 2019-02-24.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

typealias SQLProcessAlertCallback = (_ sql:String, _ db:String, _ success:Bool, _ info:String?) -> Void

class SQLProcessAlertController : BaseViewController {

    weak var connectManager:DBConnectionManager?

    var hint:String = ""
    var sql:String = ""
    var db:String = ""
    var inputArea : CNTextView?

    var callback:SQLProcessAlertCallback?

    override func viewDidLoad() {
        super.viewDidLoad()
        let closeButton = self.generateNavBarIconItem(imageName: "close", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton
        let saveButton = self.generateNavBarIconItem(imageName: "check", target: self, action: #selector(saveAction), tintColor: UIColor.red)
        self.navigationItem.rightBarButtonItem = saveButton

        self.navigationController?.title = title

        let hintLabel = UILabel()
        hintLabel.font = UIFont.systemFont(ofSize: 14)
        hintLabel.textAlignment = .center
        hintLabel.text = hint
        self.view.addSubview(hintLabel)

        let divider = UIView()
        divider.backgroundColor = UIColor.lightGray
        self.view.addSubview(divider)

        inputArea = CNTextView()
        inputArea?.text = sql
        inputArea?.isEditable = false
        inputArea?.isSelectable = true
        self.view.addSubview(inputArea!)

        if self.navigationController == nil{
            topMargin = 0
        }else {
            topMargin = self.navigationController!.navigationBar.frame.size.height
        }

        hintLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(topMargin + 10)
            maker.width.equalToSuperview().offset(-20)
            maker.centerX.equalToSuperview()
        }

        divider.snp.makeConstraints { maker in
            maker.top.equalTo(hintLabel.snp.bottom).offset(10)
            maker.width.equalToSuperview()
            maker.height.equalTo(0.5)
        }

        inputArea?.snp.makeConstraints { maker in
            maker.top.equalTo(divider.snp.bottom)
            maker.width.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
    }

    @objc func closeAction(){
        self.dismiss(animated: true)
    }

    @objc func saveAction(){

        if connectManager != nil{
            self.showLoading()
            connectManager?.addQuery(sql: sql, db: db) {[unowned self] (results, sql, db, info, status) in
                self.hideLoading()
                if results == nil || status != 0 {
                    self.showFailurePop("Process Failed", info)
                }
                else {
                    self.callback?(sql, db, status == 0, info)
                    self.dismiss(animated: true)
                }
            }
        }
        else {
            showFailurePop("Process Failed", "Lost Connection")
        }
    }
}
