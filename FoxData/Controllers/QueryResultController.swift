//
// Created by Zach Wang on 2019-01-30.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit
import Highlightr

private var ObserveContext = 0

class QueryResultController: BaseViewController {
    private var spreadView:SVSpreadsheetView?
    private var actionView:QueryResultActionView?

    var data:[[DBQueryResultItemModel]]? {
        didSet {
            spreadView?.data = data ?? []
        }
    }

    weak var delegate:QueryResultDelegate?
    
    var showResult = true {
        didSet {
            subscribeTapControl.isHidden = showResult
        }
    }
    
    private var subscribeTapControl = UIControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.actionView = QueryResultActionView()
        self.actionView?.delegate = self
        self.view.addSubview(self.actionView!)

        let divider = UIView()
        divider.backgroundColor = UIColor.lightGray
        self.view.addSubview(divider)

        self.spreadView = SVSpreadsheetView()
        self.spreadView?.backgroundColor = UIColor.white
        self.spreadView?.delegate = self
        self.view.addSubview(self.spreadView!)
        
        subscribeTapControl.isHidden = showResult
        subscribeTapControl.addTarget(self, action: #selector(tapToSubscribe), for: .touchUpInside)
        self.view.addSubview(subscribeTapControl)

        self.spreadView?.data = []

        self.actionView?.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.height.equalTo(30)
        }

        divider.snp.makeConstraints { maker in
            maker.top.equalTo(self.actionView!.snp.bottom)
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.height.equalTo(1)
        }

        self.spreadView?.snp.makeConstraints { maker in
            maker.top.equalTo(divider.snp.bottom)
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        
        subscribeTapControl.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        
        initTapSubscribeView()

        self.actionView?.copyButton?.isEnabled = false
        self.actionView?.editButton?.isEnabled = false
        self.actionView?.previewButton?.isEnabled = false
        self.actionView?.deleteButton?.isEnabled = false

    }
    
    @objc func tapToSubscribe(){
        let controller = SubscriptionController.init()
        controller.callback = {
            
        }
        let nav = UINavigationController.init(rootViewController: controller)
        nav.modalPresentationStyle = .formSheet
        self.present(nav, animated: true, completion: nil)
    }
    
    private func initTapSubscribeView() {
        let image = UIImage.init(named: "lock_cross")!;
        let image2 = UIImage.init(cgImage: image.cgImage!, scale: image.scale, orientation: image.imageOrientation)
        subscribeTapControl.backgroundColor = UIColor.init(patternImage: image2)
        
        let label = UILabel.init()
        label.text = "Please subscribe a plan to unlock all features.\nTap to subscribe!"
        label.textAlignment = .center
        label.backgroundColor = UIColor.white
        label.numberOfLines = 0
        subscribeTapControl.addSubview(label)
        
        label.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.equalTo(200)
        }
    }

}

extension QueryResultController : SVSpreadsheetViewDelegate{
    func spreadSheetViewItemDidTap(_ spreadSheet:SVSpreadsheetView, row:Int, column:Int, item:DBQueryResultItemModel){
        self.actionView?.copyButton?.isEnabled = true
        self.actionView?.editButton?.isEnabled = true
        self.actionView?.previewButton?.isEnabled = true
        self.actionView?.deleteButton?.isEnabled = true
    }
    func spreadSheetViewRowDidTap(_ spreadSheet:SVSpreadsheetView, row:Int){
        self.actionView?.copyButton?.isEnabled = true
        self.actionView?.editButton?.isEnabled = true
        self.actionView?.previewButton?.isEnabled = false
        self.actionView?.deleteButton?.isEnabled = false
    }
    func spreadSheetViewColumnDidTap(_ spreadSheet:SVSpreadsheetView, column:Int){
        self.actionView?.copyButton?.isEnabled = true
        self.actionView?.editButton?.isEnabled = false
        self.actionView?.previewButton?.isEnabled = false
        self.actionView?.deleteButton?.isEnabled = false
    }
    func spreadSheetAllSelected(){
        self.actionView?.copyButton?.isEnabled = true
        self.actionView?.editButton?.isEnabled = true
        self.actionView?.previewButton?.isEnabled = true
        self.actionView?.deleteButton?.isEnabled = true
    }
    func spreadSheetSelectionCleared(){
        self.actionView?.copyButton?.isEnabled = false
        self.actionView?.editButton?.isEnabled = false
        self.actionView?.previewButton?.isEnabled = false
        self.actionView?.deleteButton?.isEnabled = false
    }
}

extension QueryResultController : QueryResultActionDelegate{
    func copy() {
        self.delegate?.queryResultCopy(indexPaths: spreadView!.selectedItems)
    }

    func preview() {
        self.delegate?.queryResultPreview(indexPaths: spreadView!.selectedItems)
    }

    func edit() {
        self.delegate?.queryResultEdit(indexPaths: spreadView!.selectedItems)
    }

    func delete() {
        self.delegate?.queryResultDelete(indexPaths: spreadView!.selectedItems)
    }
}

protocol QueryResultDelegate : class{
    func queryResultCopy(indexPaths:[IndexPath])
    func queryResultPreview(indexPaths:[IndexPath])
    func queryResultEdit(indexPaths:[IndexPath])
    func queryResultDelete(indexPaths:[IndexPath])
    
}
