//
// Created by Zach Wang on 2019-02-10.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

class SQLInputTabView : UIView{

    private var tabView:UICollectionView?

    var tabTitles:[String] = ["New Query"]

    var activatedIndex:Int = 0 {
        didSet {
            tabView?.reloadData()
            
            tabView?.scrollToItem(at: IndexPath.init(row: activatedIndex, section: 0), at: .centeredHorizontally, animated: true)
        }
    }

    weak var delegate:SQLInputTabViewDelegate?

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
        self.backgroundColor = UIColor.init(white: 0.9, alpha: 1)

//        let layout = MTMultipleTabLayout()
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize.init(width: 200, height: 30)
        layout.minimumInteritemSpacing = 0.5
        layout.minimumLineSpacing = 0.5
        tabView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        tabView?.register(MTTabCell.self, forCellWithReuseIdentifier: "Cell")
        tabView?.backgroundColor = nil
        tabView?.showsHorizontalScrollIndicator = false
        tabView?.showsVerticalScrollIndicator = false
        tabView?.decelerationRate = .fast
        tabView?.allowsMultipleSelection = false
        tabView?.delegate = self
        tabView?.dataSource = self
        self.addSubview(tabView!)

        let divider = UIView()
        divider.backgroundColor = UIColor.lightGray
        self.addSubview(divider)

        let newButton = UIButton.init(type: .roundedRect)
        newButton.setImage(UIImage.init(named: "plus"), for: .normal)
        newButton.imageView?.contentMode = .scaleAspectFit
        newButton.tintColor = UIColor.darkGray
        newButton.imageEdgeInsets = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
        newButton.addTarget(self, action: #selector(addNewTab), for: .touchUpInside)
        self.addSubview(newButton)

        newButton.snp.makeConstraints { maker in
            maker.height.equalToSuperview()
            maker.width.equalTo(40)
            maker.right.equalToSuperview()
        }

        divider.snp.makeConstraints { maker in
            maker.right.equalTo(newButton.snp.left)
            maker.height.equalToSuperview()
            maker.width.equalTo(0.5)
        }

        tabView?.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.right.equalTo(divider.snp.left)
            maker.height.equalToSuperview()
        }
    }

    func reload(){
        tabView?.layoutIfNeeded()
        tabView?.reloadData()
    }

    @objc private func addNewTab(){
        addANewTab(title: nil)
    }

    func modifyTab(title:String, index:Int){
        if index >= 0 && index < tabTitles.count{
            tabTitles[index] = title
        }
        tabView?.reloadData()
    }

    func addANewTab(title:String?){
        if title == nil || title!.isEmpty{
            tabTitles.append("New Query")
        }
        else {
            tabTitles.append(title!)
        }

        let toIndex = tabTitles.count - 1
        self.activatedIndex = toIndex

        self.delegate?.addNewTab(position: toIndex)
    }
}

extension SQLInputTabView : UICollectionViewDelegate{
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        delegate?.showTab(position: indexPath.row, previousIndex: activatedIndex, close: false)

        self.activatedIndex = indexPath.row

    }

}

extension SQLInputTabView : UICollectionViewDataSource{
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tabTitles.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! MTTabCell
        let name = tabTitles[indexPath.row]
        cell.indexPath = indexPath
        cell.label.text = name
        cell.active = indexPath.row == self.activatedIndex
        cell.delegate = self
        return cell
    }
}

extension SQLInputTabView : MTTabCellDelegate{
    func close(indexPath: IndexPath?) {
        guard let index = indexPath?.row else {
            return
        }

        var nextInt = index - 1
        if nextInt < 0 {
            nextInt = 0
        }
        tabTitles.remove(at: index)

        if tabTitles.isEmpty{
            tabTitles.append("New Query")
        }

        self.activatedIndex = nextInt
        self.delegate?.showTab(position: nextInt, previousIndex: index, close: true)

    }
}

protocol SQLInputTabViewDelegate :class {
    ///添加新标签
    func addNewTab(position:Int)

    ///显示第N个标签内容. 如果closedIndex < 0 则为未关闭
    func showTab(position:Int, previousIndex:Int, close:Bool)
}
