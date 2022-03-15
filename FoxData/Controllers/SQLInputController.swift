//
// 处理输入
// Created by Zach Wang on 2019-01-30.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit

class SQLInputController : BaseViewController {

    weak var delegate:SQLInputDelegate?
    
    /// 用于记录是否是因为输入内容导致位置变化. 用于区别点击和输入导致
    private var isTextSelectChangeByInput = false
    
    private let boldFont = UIFont.boldSystemFont(ofSize: 14)
    private let italicFont = UIFont.italicSystemFont(ofSize: 14)
    private let defaultFont = UIFont.systemFont(ofSize: 14)

    private var inputTab = SQLInputTabView()
    private var inputArea:CNTextView?

    private var contents:[String] = [""]

    private var activateIndex:Int {
        get {
            return inputTab.activatedIndex
        }
        set {
            inputTab.activatedIndex = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        inputArea = CNTextView(frame: self.view.bounds)
        inputArea?.delegate = self
        self.view.addSubview(inputArea!)

        inputTab.delegate = self
        self.view.addSubview(inputTab)

        let divider = UIView()
        divider.backgroundColor = UIColor.darkGray
        self.view.addSubview(divider)

        inputTab.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.top.equalToSuperview()
            maker.right.equalToSuperview()
            maker.height.equalTo(30)
        }

        divider.snp.makeConstraints { maker in
            maker.top.equalTo(inputTab.snp.bottom)
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.height.equalTo(0.5)
        }

        inputArea?.snp.makeConstraints { maker in
            maker.top.equalTo(divider.snp.bottom)
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        initSQLSyntax()
    }

    func setText(_ text:String, title:String?, newTab:Bool){
        if !newTab || contents[activateIndex] == ""{
            if title != nil && !title!.isEmpty{
                inputTab.modifyTab(title: title!, index: activateIndex)
            }
            contents[activateIndex] = text
            inputArea?.text = text
        }
        else {

            //先添加内容. 因为添加tab后会判断当前index是否越界而增加内容.
            contents.append(text)

            inputTab.addANewTab(title: title)
        }

    }
    
    func getTextView()->UITextView {
        return self.inputArea!
    }

    private func initSQLSyntax(){
        // TODO 下个版本
        self.inputArea?.tokens = [
            CNToken.init(name: "reserved_words", expression: "", attributes: [
                NSAttributedString.Key.font:boldFont,
                NSAttributedString.Key.foregroundColor:UIColor.blue
            ]),
        ]
    }

    func getText()->String{
        return inputArea!.text
    }

    func getInputAreaOrigin() -> CGPoint {
        let inputAreaOrigin = self.inputArea!.frame.origin
        let selfOrigin = self.view.frame.origin
        return CGPoint.init(x: selfOrigin.x + inputAreaOrigin.x, y: selfOrigin.y + inputAreaOrigin.y)
    }
}

extension SQLInputController : SQLInputTabViewDelegate{
    func addNewTab(position: Int) {
        if position >= contents.count{
            for _ in 0..<(contents.count - position + 1) {
                contents.append("")
            }
        }

        inputArea?.text = contents[position]
    }

    func showTab(position: Int, previousIndex: Int, close: Bool) {
        if close && previousIndex >= 0 {
            contents.remove(at: previousIndex)
        }
        else if previousIndex >= 0 {
            contents[previousIndex] = getText()
        }

        if position >= contents.count{
            for _ in 0..<(contents.count - position + 1) {
                contents.append("")
            }
        }

        inputArea?.text = contents[position]
    }
}

extension SQLInputController : UITextViewDelegate{
    public func textViewDidChange(_ textView: UITextView) {
        contents[activateIndex] = textView.text
        
        let selectedRange = textView.selectedRange
        let charArray = findRevokeKeywordTree(textView, selectedRange)
        var cursorPoint:CGPoint? = nil
        if let cursorPosition = textView.selectedTextRange?.start {
            
            let caretPositionRectangle: CGRect = textView.caretRect(for: cursorPosition)
            cursorPoint = caretPositionRectangle.origin
        }
        self.delegate?.onRevokeChainCreated(charArray, cursorPoint)
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        self.isTextSelectChangeByInput = true
        return true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if !self.isTextSelectChangeByInput {
            self.delegate?.onRevokeChainCreated([], nil)
        }
        self.isTextSelectChangeByInput = false
    }
    
    /// isDot: 从 . 往前调用, 因此再遇到.的时候就直接跳过不再往前取了
    func findRevokeKeywordTree(_ textView:UITextView, _ range:NSRange, isDot:Bool = false, currentDeep:Int = 0, maxDeep:Int = Int.max) -> [String]{
        
        var arr:[String] = []
        if currentDeep >= maxDeep {
            return arr
        }
        let beginning = textView.beginningOfDocument
        let start = textView.position(from: beginning, offset: range.location)
        let end = textView.position(from: start!, offset: range.length)
        let wordRange = textView.tokenizer.rangeEnclosingPosition(end!, with: .word, inDirection: UITextDirection.init(rawValue: UITextLayoutDirection.left.rawValue))
        let charRange = textView.tokenizer.rangeEnclosingPosition(end!, with: .character, inDirection: UITextDirection.init(rawValue: UITextLayoutDirection.left.rawValue))
        
        if wordRange != nil {// 当前位置是个单词
            
            //查单词前的字
            let currWordStart = textView.offset(from: beginning, to: wordRange!.start)
            
            
            if currWordStart > 0 {
                let prev = findRevokeKeywordTree(textView, NSRange.init(location: currWordStart, length: 0))
                if prev.count > 0{
                    arr.append(contentsOf: prev)
                }
            }
            
            //当前输入中的字
            let currWord = textView.text(in: textView.textRange(from: wordRange!.start, to: end!)!)!
            arr.append(currWord)
        }
        else if charRange != nil && !isDot{ //判断 .
            
            let currChar = textView.text(in: textView.textRange(from: charRange!.start, to: end!)!)!
            if currChar == "."{
                let prev = findRevokeKeywordTree(textView, NSRange.init(location: range.location - 1, length: 0), isDot:true)
                if prev.count > 0{
                    arr.append(contentsOf: prev)
                }
                arr.append(".")
            }
        }
        
        
        return arr
    }
}

protocol SQLInputDelegate:class {
    /// chain会有很多., 用于分割词.
    func onRevokeChainCreated(_ chain:[String], _ cursorPoint:CGPoint?)
}
