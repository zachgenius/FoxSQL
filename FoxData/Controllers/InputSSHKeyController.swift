// 输入SSH Key 界面
// Created by Zach Wang on 2019-03-18.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

typealias InputSSHKeyComplete = (_ pubKey:String, _ privKey:String, _ pwd:String) -> Void

class InputSSHKeyController : BaseViewController {
    var pubKey:String = ""
    var privKey:String = ""
    var privKeyPwd:String = ""


    private var pubKeyArea:UITextView?
    private var privKeyArea:UITextView?
    private var pwdInput:LRTextField?

    var callback:InputSSHKeyComplete?

    override func viewDidLoad() {
        super.viewDidLoad()
        let closeButton = self.generateNavBarIconItem(imageName: "back", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton
        let saveButton = self.generateNavBarIconItem(imageName: "check", target: self, action: #selector(saveAction), tintColor: UIColor.red)
        self.navigationItem.rightBarButtonItem = saveButton
        self.title = "SSH Public Key"
        
        let scrollView = UIScrollView.init()
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview()
            maker.top.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalToSuperview()
        }


        let hintLabel = UILabel()
        hintLabel.font = UIFont.systemFont(ofSize: 14)
        hintLabel.numberOfLines = 0
        hintLabel.text = "Please paste your public key\n" +
                "e.g.: ssh-rsa XXXXXXXXXXX example@mail.com"
        scrollView.addSubview(hintLabel)

        let divider = UIView()
        divider.backgroundColor = UIColor.lightGray
        self.view.addSubview(divider)

        let textContainerInset = UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)

        pubKeyArea = UITextView()
        pubKeyArea?.textContainerInset = textContainerInset
        pubKeyArea?.text = pubKey
        pubKeyArea?.isEditable = true
        pubKeyArea?.isSelectable = true
        scrollView.addSubview(pubKeyArea!)

        pwdInput = LRTextField.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.width, height: 50), labelHeight: 16)
        pwdInput!.placeholder = "Private Key Password (Optional)"
        pwdInput!.backgroundColor = UIColor.white
        pwdInput?.text = self.privKeyPwd
        scrollView.addSubview(pwdInput!)

        let hintLabel2 = UILabel()
        hintLabel2.font = UIFont.systemFont(ofSize: 14)
        hintLabel2.numberOfLines = 0
        hintLabel2.text = "Please paste your private key\n" +
                "-----BEGIN RSA PRIVATE KEY-----"
        scrollView.addSubview(hintLabel2)

        let divider2 = UIView()
        divider2.backgroundColor = UIColor.lightGray
        scrollView.addSubview(divider2)

        privKeyArea = UITextView()
        privKeyArea?.textContainerInset = textContainerInset
        privKeyArea?.text = privKey
        privKeyArea?.isEditable = true
        privKeyArea?.isSelectable = true
        scrollView.addSubview(privKeyArea!)

        let hintLabel3 = UILabel()
        hintLabel3.font = UIFont.systemFont(ofSize: 14)
        hintLabel3.numberOfLines = 0
        hintLabel3.text = "-----END RSA PRIVATE KEY-----"

        scrollView.addSubview(hintLabel3)

//        if self.navigationController == nil{
//            topMargin = 0
//        }else {
//            topMargin = self.navigationController!.navigationBar.frame.size.height
//        }

        hintLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(10)
            maker.width.equalToSuperview().offset(-20)
            maker.centerX.equalToSuperview()
        }

        divider.snp.makeConstraints { maker in
            maker.top.equalTo(hintLabel.snp.bottom).offset(10)
            maker.width.equalToSuperview()
            maker.height.equalTo(0.5)
        }

        pubKeyArea?.snp.makeConstraints { maker in
            maker.top.equalTo(divider.snp.bottom)
            maker.width.equalToSuperview()
            maker.height.equalTo(80)
        }

        pwdInput?.snp.makeConstraints { maker in
            maker.top.equalTo(pubKeyArea!.snp.bottom).offset(30)
            maker.width.equalToSuperview()
            maker.height.equalTo(50)
        }

        hintLabel2.snp.makeConstraints { maker in
            maker.top.equalTo(pwdInput!.snp.bottom).offset(10)
            maker.width.equalToSuperview().offset(-20)
            maker.centerX.equalToSuperview()
        }

        divider2.snp.makeConstraints { maker in
            maker.top.equalTo(hintLabel2.snp.bottom).offset(5)
            maker.width.equalToSuperview()
            maker.height.equalTo(0.5)
        }

        privKeyArea?.snp.makeConstraints { maker in
            maker.top.equalTo(divider2.snp.bottom)
            maker.width.equalToSuperview()
            maker.height.equalTo(200)
        }
        hintLabel3.snp.makeConstraints { maker in
            maker.top.equalTo(privKeyArea!.snp.bottom).offset(5)
            maker.width.equalToSuperview().offset(-20)
            maker.centerX.equalToSuperview()
        }

    }

    @objc func closeAction(){
        self.navigationController?.popViewController(animated: true)
    }

    @objc func saveAction(){
        self.callback?(self.pubKeyArea!.text, self.privKeyArea!.text, self.pwdInput!.text!)
        self.navigationController?.popViewController(animated: true)
    }

}
