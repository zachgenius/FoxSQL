//
// 第一列是要显示行数, 第一行是column name
// Created by Zach Wang on 2019-02-08.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

class SVSpreadsheetLayout:UICollectionViewLayout {
    public static let defaultMaxWidth:CGFloat = 500
    public static let defaultMinWidth:CGFloat = 40
    public static let defaultHeight:CGFloat = 30
    public static let indexAreaWidth:CGFloat = 30

    private var itemSizes:[CGSize] = []
    private var itemAttributes:[[UICollectionViewLayoutAttributes]] = [[]]
    private var contentSize:CGSize = CGSize.zero

    private var _longestStringEachColumns:[DBQueryResultItemModel] = []

    var longestStringEachColumns:[DBQueryResultItemModel] {
        get {
            return _longestStringEachColumns
        }
        set {
            _longestStringEachColumns = newValue
            self.itemSizes = []
            self.itemAttributes = []
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes:[UICollectionViewLayoutAttributes] = []
        for item in self.itemAttributes {
            attributes.append(contentsOf: item.filter { (evaluatedObject: UICollectionViewLayoutAttributes) -> Bool in
                return rect.intersects(evaluatedObject.frame)
            })
        }
        return attributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.itemAttributes[indexPath.section][indexPath.row]
    }

    override var collectionViewContentSize: CGSize {
        return self.contentSize
    }

    override func prepare() {
        guard let collectionView = collectionView else {
            return
        }

        if collectionView.numberOfSections == 0 {
            return
        }

        if itemAttributes.count != collectionView.numberOfSections {
            generateItemAttributes(collectionView: collectionView)
            return
        }

        for section in 0..<collectionView.numberOfSections {
            for item in 0..<collectionView.numberOfItems(inSection: section) {
                if section != 0 && item != 0 {
                    continue
                }

                let attributes = layoutAttributesForItem(at: IndexPath(item: item, section: section))!
                if section == 0 {
                    var frame = attributes.frame
                    frame.origin.y = collectionView.contentOffset.y
                    attributes.frame = frame
                }

                if item == 0 {
                    var frame = attributes.frame
                    frame.origin.x = collectionView.contentOffset.x
                    attributes.frame = frame
                }
            }
        }

    }
}

extension SVSpreadsheetLayout{

    func reload(){
        self.itemAttributes = []
        self.itemSizes = []
        invalidateLayout()
    }

    func generateItemAttributes(collectionView: UICollectionView) {
        let numberOfColumns = collectionView.numberOfItems(inSection: 0)

        if self.itemSizes.count != numberOfColumns {
            calculateItemSizes(collectionView: collectionView)
        }

        var column = 0
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var contentWidth: CGFloat = 0

        itemAttributes.removeAll()

        for section in 0..<collectionView.numberOfSections {
            var sectionAttributes: [UICollectionViewLayoutAttributes] = []

            for index in 0..<numberOfColumns{
                let itemSize = itemSizes[index]
                let indexPath = IndexPath(item: index, section: section)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemSize.width, height: itemSize.height).integral

                if section == 0 && index == 0 {
                    // First cell should be on top
                    attributes.zIndex = 1024
                } else if section == 0 || index == 0 {
                    // First row/column should be above other cells
                    attributes.zIndex = 1023
                }

                // 第一行
                if section == 0 {
                    var frame = attributes.frame
                    frame.origin.y = collectionView.contentOffset.y
                    attributes.frame = frame
                }
                // 第一列
                if index == 0 {
                    var frame = attributes.frame
                    frame.origin.x = collectionView.contentOffset.x
                    attributes.frame = frame
                }

                sectionAttributes.append(attributes)

                xOffset += itemSize.width
                column += 1

                if column == numberOfColumns {
                    if xOffset > contentWidth {
                        contentWidth = xOffset
                    }

                    column = 0
                    xOffset = 0
                    yOffset += itemSize.height
                }
            }

            itemAttributes.append(sectionAttributes)
        }

        if let attributes = itemAttributes.last?.last {
            contentSize = CGSize(width: contentWidth, height: attributes.frame.maxY)
        }
    }

    func calculateItemSizes(collectionView: UICollectionView) {
        itemSizes = []
        let numberOfColumns = collectionView.numberOfItems(inSection: 0)

        for index in 0..<numberOfColumns {
            itemSizes.append(sizeForItemWithColumnIndex(index, numberOfColumns: numberOfColumns))
        }
    }

    func sizeForItemWithColumnIndex(_ columnIndex: Int, numberOfColumns:Int) -> CGSize {

        //第一列为序号区域
        if columnIndex == 0{
            return CGSize(width: SVSpreadsheetLayout.indexAreaWidth, height: SVSpreadsheetLayout.defaultHeight)
        }

        //最后一列是伸缩区域
        if columnIndex == numberOfColumns - 1{
            var collectionContentWidth:CGFloat = 0
            for item in itemSizes {
                collectionContentWidth += item.width
            }
            let collectionBoundsWidth = self.collectionView!.frame.width
            if collectionContentWidth >= collectionBoundsWidth {
                return CGSize(width: 1, height: SVSpreadsheetLayout.defaultHeight)
            }
            else {
                return CGSize(width: collectionBoundsWidth - collectionContentWidth, height: SVSpreadsheetLayout.defaultHeight)
            }
        }

        let item = self.longestStringEachColumns[columnIndex - 1]
        
        let text: NSString = (item.text ?? "NULL") as NSString

        let size: CGSize = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: SVItemCell.textFont)])
        var width: CGFloat = size.width + SVItemCell.margin*4
        if width > SVSpreadsheetLayout.defaultMaxWidth {
            width = SVSpreadsheetLayout.defaultMaxWidth
        }
        return CGSize(width: width, height: SVSpreadsheetLayout.defaultHeight)
    }
}
