//
// Created by Zach Wang on 2019-03-02.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

class DBResultItemPreviewController :BaseViewController {
    var resultItem:DBQueryResultItemModel?
    weak var dbManager:DBConnectionManager?

    private var textView:UITextView?
    private var imageView = UIImageView(image: UIImage.init(named: "file"))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Preview"
        let closeButton = self.generateNavBarIconItem(imageName: "close", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton

        textView = UITextView()
        textView?.font = UIFont.systemFont(ofSize: 14)
        textView?.isEditable = false
        textView?.isSelectable = true

        if resultItem?.type == .blob {
            self.view.addSubview(imageView)
            imageView.contentMode = .scaleAspectFit
            imageView.snp.makeConstraints { maker in
                maker.center.equalToSuperview()
                maker.width.equalTo(70)
                maker.height.equalTo(70)
            }
        }
        else {
            textView?.text = resultItem?.text
            self.view.addSubview(textView!)
            textView?.snp.makeConstraints { maker in
                maker.left.equalToSuperview().offset(10)
                maker.top.equalToSuperview().offset(20)
                maker.right.equalToSuperview().offset(-10)
                maker.bottom.equalToSuperview().offset(-10)
            }
            let copyButton = self.generateNavBarIconItem(imageName: "copy", target: self, action: #selector(copyAction), tintColor: UIColor.red)
            self.navigationItem.rightBarButtonItem = copyButton
        }

    }

    @objc func closeAction(){
        self.dismiss(animated: true)
    }

    @objc func copyAction(){
        if resultItem!.type == .blob{
            showSuccessPop("Copy", "BLOB item cannot be copied")
        }
        else {
            let pasteboard = UIPasteboard.general
            pasteboard.string = resultItem!.text
            showSuccessPop("Copy", "Copy succeeded")
        }
    }
}
