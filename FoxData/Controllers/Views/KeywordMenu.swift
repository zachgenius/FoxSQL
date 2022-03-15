//
// Created by Zach Wang on 2019-04-16.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

class KeywordMenu : UITableViewController{

    var keywords:[KeywordModel] = [] {
        didSet {
            focusIndex = 0
            tableView.reloadData()
        }
    }
    
    var keywordCallback:((_ keyword:KeywordModel) -> Void)?
    
    private var focusIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.isHidden = true
        self.tableView.bounces = false
        self.view.layer.borderWidth = 0.5
        self.view.layer.borderColor = UIColor.darkGray.cgColor
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keywords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil{
            cell = UITableViewCell.init(style: .value1, reuseIdentifier: "cell")
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 16)
            cell?.detailTextLabel?.font =  UIFont.systemFont(ofSize: 14)
        }
        let key = keywords[indexPath.row]
        cell!.textLabel?.text = key.title
        cell!.detailTextLabel?.text = key.type.rawValue
        
        if self.focusIndex == indexPath.row {
            cell?.backgroundColor = UIColor.blue
            cell?.textLabel?.textColor = UIColor.white
            cell?.detailTextLabel?.textColor = UIColor.white
        }
        else {
            cell?.backgroundColor = UIColor.white
            cell?.textLabel?.textColor = UIColor.darkGray
            cell?.detailTextLabel?.textColor = UIColor.gray
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let key = keywords[indexPath.row]
        keywordCallback?(key)
    }
    
    func updateFrame(_ x:CGFloat, _ y:CGFloat, _ maxHeight:CGFloat = 200){
        if keywords.count == 0 {
            self.view.isHidden = true
        }else{
            self.view.isHidden = false
            
            var height:CGFloat = CGFloat(keywords.count) * 30.0
            if height > maxHeight {
                height = maxHeight
            }
            
            self.view.frame = CGRect.init(x: x, y: y, width: 200, height: height)
        }
    }
    
    func moveFocusUp(){
        if keywords.count == 0 {
            return
        }
        self.focusIndex -= 1
        if self.focusIndex < 0 {
            self.focusIndex = keywords.count - 1
        }
        self.tableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {[unowned self] in
            self.scrollToIndex(self.focusIndex)
        }
    }
    
    func moveFocusDown(){
        if keywords.count == 0 {
            return
        }
        self.focusIndex += 1
        if self.focusIndex >= keywords.count {
            self.focusIndex = 0
        }
        self.tableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {[unowned self] in
            self.scrollToIndex(self.focusIndex)
        }
    }
    
    func scrollToIndex(_ index:Int) {
        let visibleIndexes = self.tableView.indexPathsForVisibleRows
        
        if visibleIndexes == nil || visibleIndexes!.count < 6 {// 最大200高度, 因此一次最多能显示下6个, 因此不需要滚动
            return
        }
        
        let firstVisible = visibleIndexes![1] // 取第二个
        let lastVisible = visibleIndexes![visibleIndexes!.count - 2] // 取倒数第二个
        
        if firstVisible.row > index ||  lastVisible.row < index {//需要向下滑动
            self.tableView.scrollToRow(at: IndexPath.init(row: index, section: 0), at: .none, animated: false)
        }
        
    }
    
    func confirm(){
        let key = keywords[self.focusIndex]
        keywordCallback?(key)
    }
}
