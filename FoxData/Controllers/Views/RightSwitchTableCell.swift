//
//  RightSwitchTableCell.swift
//  FoxData
//
//  Created by Zach Wang on 4/17/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit

class RightSwitchTableCell: UITableViewCell {

    private(set) var rightSwitch:UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initViews(){
        rightSwitch = UISwitch()
        self.addSubview(rightSwitch)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let swSize = rightSwitch.sizeThatFits(self.bounds.size)
        rightSwitch.frame = CGRect.init(x: self.bounds.width - 10 - swSize.width,
                                        y: (self.bounds.height - swSize.height) / 2,
                                        width: swSize.width, height: swSize.height)
        
    }
    
}
