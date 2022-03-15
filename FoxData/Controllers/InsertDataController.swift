//
// 给表插入数据

// Created by Zach Wang on 2019-02-27.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

typealias InsertDataCallback = (_ table:String, _ db:String, _ success:Bool, _ info:String?) -> Void

class InsertDataController :BaseViewController  {

    var table:String?
    weak var connectManager:DBConnectionManager?
    var callback:InsertDataCallback?

    var db:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Insert Data"

        let closeButton = self.generateNavBarIconItem(imageName: "close", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton
        let saveButton = self.generateNavBarIconItem(imageName: "check", target: self, action: #selector(saveAction), tintColor: UIColor.red)
        self.navigationItem.rightBarButtonItem = saveButton


    }

    @objc func closeAction(){
        self.dismiss(animated: true)
    }

    @objc func saveAction(){
    }

}
