//
// Created by Zach Wang on 2019-02-10.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

class QueryResultActionView: UIView {

    weak var delegate:QueryResultActionDelegate?

    var copyButton:UIButton?
    var editButton:UIButton?
    var previewButton:UIButton?
    var deleteButton:UIButton?

    private let buttonHeight = 25
    private let buttonFont = UIFont.systemFont(ofSize: 12)
    private let margin = 10

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func initViews(){
        copyButton = generateButton(text: "Copy")
        copyButton?.setImage(UIImage.init(named: "copy"), for: .normal)
        editButton = generateButton(text: "Edit")
        editButton?.setImage(UIImage.init(named: "edit"), for: .normal)
        previewButton = generateButton(text: "Preview")
        previewButton?.setImage(UIImage.init(named: "view"), for: .normal)
        deleteButton = generateButton(text: "Delete")
        deleteButton?.setImage(UIImage.init(named: "delete"), for: .normal)

        self.addSubview(copyButton!)
        //todo 下个版本
//        self.addSubview(editButton!)
        self.addSubview(previewButton!)
//        self.addSubview(deleteButton!)

//        self.deleteButton!.snp.makeConstraints { maker in
//            maker.height.equalTo(buttonHeight)
//            maker.width.equalTo(buttonHeight)
//            maker.centerY.equalTo(self)
//            maker.right.equalToSuperview().offset(-2*margin)
//        }
//        self.editButton!.snp.makeConstraints { maker in
//            maker.height.equalTo(buttonHeight)
//            maker.width.equalTo(buttonHeight)
//            maker.centerY.equalTo(self)
//            maker.right.equalTo(deleteButton!.snp.left).offset(-margin)
//        }
        self.previewButton!.snp.makeConstraints { maker in
            maker.height.equalTo(buttonHeight)
            maker.width.equalTo(buttonHeight)
            maker.centerY.equalTo(self)
            maker.right.equalToSuperview().offset(-2*margin)
//            maker.right.equalTo(deleteButton!.snp.left).offset(-margin)
//            maker.right.equalTo(editButton!.snp.left).offset(-margin)
        }
        self.copyButton!.snp.makeConstraints { maker in
            maker.height.equalTo(buttonHeight)
            maker.width.equalTo(buttonHeight)
            maker.centerY.equalTo(self)
            maker.right.equalTo(previewButton!.snp.left).offset(-margin)
        }

    }

    func generateButton(text:String)->UIButton{
        let button = UIButton.init(type: .roundedRect)
        button.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor.black
        return button
    }

    @objc func buttonAction(sender:UIButton){

        switch sender {
        case copyButton:
            delegate?.copy()
            break
        case editButton:
            delegate?.edit()
            break
        case previewButton:
            delegate?.preview()
            break
        case deleteButton:
            delegate?.delete()
            break
        default:

            break
        }
    }
}

protocol QueryResultActionDelegate:class {
    func edit()
    func preview()
    func copy()
    func delete()
}