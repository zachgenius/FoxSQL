//
//  KeywordToolbar.swift
//  FoxData 键盘上方的工具栏
//
//  Created by Zach Wang on 4/20/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit

class KeywordToolbar: UIViewController {
    var keywords:[KeywordModel] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var keywordCallback:((_ keyword:KeywordModel) -> Void)?
    
    var keyboardCloseAction:(()->Void)?
    
    private var collectionView:UICollectionView!
    private var button:UIButton!
    private let line = UIView()
    static let barHeight:CGFloat = 46
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(white: 0.96, alpha: 1)
        line.backgroundColor = UIColor.lightGray
        self.view.addSubview(line)
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.sectionInset = UIEdgeInsets.init(top: 2, left: 5, bottom: 2, right: 5)
        collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.init(white: 0.96, alpha: 1)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(KeywordToolbarCell.self, forCellWithReuseIdentifier: "cell")
        self.view.addSubview(collectionView)
        
        button = UIButton.init(type: .roundedRect)
        button.setImage(UIImage.init(named: "keyboard_down"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor.darkGray
        button.imageEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(keyboardClose), for: .touchUpInside)
        self.view.addSubview(button)
        
    }
    
    @objc private func keyboardClose(){
        keyboardCloseAction?()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        line.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.width, height: 0.5)
        collectionView.frame = CGRect.init(x: 0, y: 0.5, width: self.view.bounds.width - KeywordToolbar.barHeight, height: self.view.bounds.height)
        button.frame = CGRect.init(x: self.view.bounds.width - KeywordToolbar.barHeight, y: 0.5, width: KeywordToolbar.barHeight, height: self.view.bounds.height)
    }
}

extension KeywordToolbar : UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return keywords.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! KeywordToolbarCell
        let keyword = keywords[indexPath.row]
        if keyword.type == .snippet {
            cell.label.text = "\(keyword.title) (snippet)"
        }
        else{
            cell.label.text = keyword.title
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let keyword = keywords[indexPath.row]
        keywordCallback?(keyword)
    }
    
}

fileprivate class KeywordToolbarCell : UICollectionViewCell {
    
    let label:UILabel = UILabel.init()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        self.addSubview(label)
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = self.bounds
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        
        let labelSize = label.sizeThatFits(size)
        return CGSize.init(width: labelSize.width + 20, height: labelSize.height + 10)
    }
}
