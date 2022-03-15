// 显示sql结果的view
// Created by Zach Wang on 2019-03-01.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

class SQLMessageController : BaseViewController {
    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.backgroundColor = UIColor.white
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 14)
        self.view.addSubview(textView)
    }

    func addLog(_ log:String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let time = formatter.string(from: Date())

        let prevText:String = textView.text
        let newText = "[\(time)]\n\(log)\n\n\(prevText)"
        textView.text = newText
    }

    override func layoutAllSubviews(_ isWidthCompactLayout: Bool) {
        textView.frame = self.view.bounds
    }
}
