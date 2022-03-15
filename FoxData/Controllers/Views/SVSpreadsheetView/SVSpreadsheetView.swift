//
// spread sheet view
// Created by Zach Wang on 2019-02-08.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

protocol SVSpreadsheetViewDelegate:class {
    func spreadSheetViewItemDidTap(_ spreadSheet:SVSpreadsheetView, row:Int, column:Int, item:DBQueryResultItemModel)
    func spreadSheetViewRowDidTap(_ spreadSheet:SVSpreadsheetView, row:Int)
    func spreadSheetViewColumnDidTap(_ spreadSheet:SVSpreadsheetView, column:Int)
    func spreadSheetAllSelected()
    func spreadSheetSelectionCleared()
}

class SVSpreadsheetView:UIView{
    weak var delegate:SVSpreadsheetViewDelegate?

    var selectedItems:[IndexPath] = []

    var data:[[DBQueryResultItemModel]] {
        get {
            if _data == nil{
                return []
            }
            return _data!
        }
        set {
            _data = newValue
            if newValue.count > 0{
                var longestEachColumn:[DBQueryResultItemModel] = []
                longestEachColumn.append(contentsOf: newValue[0])
                for index in 1..<newValue.count{
                    let arr = newValue[index]
                    for inIndex in 0..<arr.count{
                        let prev = (longestEachColumn[inIndex].text ?? "") as NSString
                        let curr = (arr[inIndex].text ?? "" ) as NSString
                        if curr.size().width > prev.size().width {
                            longestEachColumn[inIndex] = arr[inIndex]
                        }
                    }
                }
                self.collectionLayout.longestStringEachColumns = longestEachColumn
            }
            else {
                self.collectionLayout.longestStringEachColumns = []
            }
            self.selectedItems = []
            self.delegate?.spreadSheetSelectionCleared()
            self.collectionView.reloadData()
        }
    }

    private var _data:[[DBQueryResultItemModel]]?

    private var _collectionView:UICollectionView?
    private var _collectionLayout:SVSpreadsheetLayout?

    private var collectionLayout:SVSpreadsheetLayout{
        if _collectionLayout == nil{
            _collectionLayout = SVSpreadsheetLayout()
        }

        return _collectionLayout!
    }

    private var collectionView:UICollectionView{
        if _collectionView == nil {

            _collectionView = UICollectionView.init(frame: self.bounds, collectionViewLayout: self.collectionLayout)
            _collectionView?.delegate = self
            _collectionView?.dataSource = self
            _collectionView?.backgroundColor = UIColor.white
            _collectionView?.register(SVItemCell.self, forCellWithReuseIdentifier: "cell")
            self.addSubview(_collectionView!)
        }
        return _collectionView!
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.frame = self.bounds

        self.collectionLayout.reload()
        self.collectionView.reloadData()
    }
}

extension SVSpreadsheetView:UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)

        if indexPath.section >= data.count || indexPath.row > data[0].count {
            return
        }

        //选中左上角, 可以设置全选
        if indexPath.section == 0 && indexPath.row == 0{
//            self.delegate?.spreadSheetAllSelected()
            return //TODO 下个版本
        }
        //选中第一行, 那么就选择整个列
        else if indexPath.section == 0{
//            self.delegate?.spreadSheetViewRowDidTap(self, row: indexPath.section)
            return //TODO 下个版本
        }
        //点了最前面的index那么就选中整行
        else if indexPath.row == 0 {
//            self.delegate?.spreadSheetViewColumnDidTap(self, column: indexPath.row - 1)
            return //TODO 下个版本
        }
        //选中单元格
        else {
            self.selectedItems = [indexPath]
        }

        collectionView.reloadData()
        let item = self.data[indexPath.section][indexPath.row - 1]
        self.delegate?.spreadSheetViewItemDidTap(self, row: indexPath.section, column: indexPath.row - 1, item: item)
    }


}

extension SVSpreadsheetView:UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! SVItemCell

        if self.selectedItems.contains(indexPath){
            cell.bgView.backgroundColor = UIColor.cyan
            cell.bgView.layer.borderWidth = 2
            cell.bgView.layer.borderColor = UIColor.black.cgColor
        }else {
            cell.bgView.backgroundColor = UIColor.init(white: 1, alpha: 0)
            cell.bgView.layer.borderWidth = 0
        }

        cell.setStyle(style: .normal)
        //数据外部时
        if indexPath.section >= data.count{
            cell.contentLabel.text = ""
            if indexPath.row == 0{
                cell.setStyle(style: .firstColumn)
            }
            else {
                if indexPath.section % 2 != 1 {
                    cell.backgroundColor = UIColor(white: 242/255.0, alpha: 1.0)
                } else {
                    cell.backgroundColor = UIColor.white
                }
            }

            return cell
        }

        //第一行 标题行
        if indexPath.section == 0 {
            cell.setStyle(style: .firstRow)
            //第一行第一例留空
            if indexPath.row == 0 {
                cell.contentLabel.text = ""
                cell.setStyle(style: .firstColumn)
            }
            //最后一列作为伸缩区域
            else if indexPath.row == collectionView.numberOfItems(inSection: indexPath.section) - 1{
                cell.contentLabel.text = ""
                cell.rightBorder.isHidden = true
            }
            else {
                let item = self.data[indexPath.section][indexPath.row - 1];
                let text = item.text
                cell.contentLabel.textAlignment = .center
                cell.contentLabel.text = text ?? ""
                if item.isPrimary {
                    cell.contentLabel.textColor = UIColor.blue
                }
                else{
                    cell.contentLabel.textColor = UIColor.darkText
                }
            }

        }
        //其他行
        else {
            if indexPath.row == 0 {
                cell.contentLabel.textAlignment = .right
                cell.contentLabel.text = String(indexPath.section)
                cell.setStyle(style: .firstColumn)
            }
            //最后一列作为伸缩区域
            else if indexPath.row == collectionView.numberOfItems(inSection: indexPath.section) - 1{
                cell.contentLabel.text = ""
                if indexPath.section % 2 != 1 {
                    cell.backgroundColor = UIColor(white: 242/255.0, alpha: 1.0)
                } else {
                    cell.backgroundColor = UIColor.white
                }
            }
            else {
                let item = self.data[indexPath.section][indexPath.row - 1];
                let text = item.text
                cell.contentLabel.text = text  ?? "NULL"
                if indexPath.section % 2 != 1 {
                    cell.backgroundColor = UIColor(white: 242/255.0, alpha: 1.0)
                } else {
                    cell.backgroundColor = UIColor.white
                }
                
                if item.isPrimary {
                    cell.contentLabel.textColor = UIColor.blue
                }
                else{
                    cell.contentLabel.textColor = UIColor.darkText
                }
            }
        }
        return cell
    }

    //多少行
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        let count = self.data.count + 1 // 增加最后一行空余

        //计算一屏幕能容纳多少行
        let maxPerPage = Int((collectionView.bounds.height / SVSpreadsheetLayout.defaultHeight).rounded(.down))
        return max(count, maxPerPage)
    }

    //多少列
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 超出行数
        if section >= self.data.count{
            if self.data.count == 0{
                return 2
            }
            else {
                let count = self.data[0].count
                return count + 2
            }
        }
        let count = self.data[section].count
        return count + 2
    }
}
