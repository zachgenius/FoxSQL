// 右侧有输入框的cell
// Created by Zach Wang on 2019-04-10.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

class RightInputTableCell : UITableViewCell {

    private(set) var rightInput:UITextField?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func initViews(){
        rightInput = UITextField()
        rightInput?.textAlignment = .right
        rightInput?.autocorrectionType = .no
        rightInput?.autocapitalizationType = .none
        self.addSubview(rightInput!)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if textLabel != nil {
            let tSize = self.textLabel!.sizeThatFits(self.bounds.size)
            rightInput?.frame = CGRect.init(x: 20 + tSize.width,
                    y: 0,
                    width: self.bounds.width - 30 - tSize.width, height: self.bounds.height)
        }
        else {
            rightInput?.frame = CGRect.init(x: 10, y: 0, width: self.bounds.width - 20, height: self.bounds.height)
        }

    }
}
