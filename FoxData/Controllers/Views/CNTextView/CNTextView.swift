//
// Created by Zach Wang on 2019-02-01.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import Highlightr

private var CNTextViewContext = 0

class CNTextView : UITextView {
    var singleFingerPanRecognizer:UIPanGestureRecognizer?
    var doubleFingerPanRecognizer:UIPanGestureRecognizer?
    var gutterBackgroundColor:UIColor = UIColor.init(white: 0.95, alpha: 1)
    var gutterLineColor:UIColor = UIColor.lightGray
    var lineCursorEnabled = true
    var tokens:[CNToken] {
        get {
            return self.syntaxTextStorage.tokens
        }
        set {
            self.syntaxTextStorage.tokens = newValue
        }
    }

    private let kCursorVelocity = 1 / 8.0
    private var lineNumberLayoutManager: CNLayoutManager?

    private var lastInputChar:String?
    private var syntaxTextStorage:CNTextStorage = CNTextStorage()

    convenience init(){
        self.init(frame: CGRect.zero)
    }

    init(frame: CGRect) {

        let highlightr = Highlightr()!
        highlightr.setTheme(to: "xcode")
        let textStorage = CodeAttributedString(highlightr: highlightr)
        textStorage.language = "sql"

//        let textStorage = CNTextStorage()

        lineNumberLayoutManager = CNLayoutManager()
        let textContainer = NSTextContainer.init(size: CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))

        //  Wrap text to the text view's frame
        textContainer.widthTracksTextView = true

        lineNumberLayoutManager!.addTextContainer(textContainer)

        textStorage.addLayoutManager(lineNumberLayoutManager!)
//        self.syntaxTextStorage = textStorage

        super.init(frame: frame, textContainer: textContainer)
        self.contentMode = .redraw // causes drawRect: to be called on frame resizing and device rotation
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setup(){
        // Setup observers
        self.addObserver(self, forKeyPath: NSStringFromSelector(#selector(setter: font)), options: .new, context: &CNTextViewContext)
        self.addObserver(self, forKeyPath: NSStringFromSelector(#selector(setter: textColor)), options: .new, context: &CNTextViewContext)
        self.addObserver(self, forKeyPath: NSStringFromSelector(#selector(setter: selectedTextRange)), options: .new, context: &CNTextViewContext)
        self.addObserver(self, forKeyPath: NSStringFromSelector(#selector(setter: selectedRange)), options: .new, context: &CNTextViewContext)

        NotificationCenter.default.addObserver(self, selector: #selector(handleTextViewDidChangeNotification(notification:)), name: UITextView.textDidChangeNotification, object: self)

        // Setup defaults
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.autocorrectionType = .no
        self.spellCheckingType = .no
        self.autocapitalizationType = .none

        self.textContainerInset = UIEdgeInsets.init(top: 8, left: self.lineNumberLayoutManager!.gutterWidth, bottom: 8, right: 0)
        
        //去掉自带的工具栏
        let item = self.inputAssistantItem
        item.leadingBarButtonGroups = []
        item.trailingBarButtonGroups = []


    }
    
    ///MARK - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == NSStringFromSelector(#selector(setter: font)) && context == &CNTextViewContext {
            if font != nil{
                self.syntaxTextStorage.defaultFont = font!
            }
        }
        else if keyPath == NSStringFromSelector(#selector(setter: textColor)) && context == &CNTextViewContext{
            if textColor != nil{
                self.syntaxTextStorage.defaultTextColor = textColor!
            }
        }
        else if (keyPath == NSStringFromSelector(#selector(setter: selectedRange)) || keyPath == NSStringFromSelector(#selector(setter: selectedTextRange))) && context == &CNTextViewContext{
            self.setNeedsDisplay()
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    /// MARK - Notifications
    @objc func handleTextViewDidChangeNotification(notification:Notification){
//        if notification.object == self{
//            let line = self.caretRect(for: self.selectedTextRange!.start)
//            let overflow = line.origin.y + line.size.height - ( self.contentOffset.y + self.bounds.size.height - self.contentInset.bottom - self.contentInset.top )
//
//            if ( overflow > 0 )
//            {
//                // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
//                // Scroll caret to visible area
//                let offset = self.contentOffset;
//                offset.y = offset.y +  overflow + 7; // leave 7 pixels margin
//                // Cannot animate with setContentOffset:animated: or caret will not appear
////            [UIView animateWithDuration:.2 animations:^{
////                [self setContentOffset:offset];
////            }];
//            }
//        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        self.lastInputChar = text
        return true
    }

    /// MARK - Line Drawing
    override func draw(_ rect: CGRect) {
        //  Drag the line number gutter background.  The line numbers them selves are drawn by LineNumberLayoutManager.
        let context = UIGraphicsGetCurrentContext()
        let bounds = self.bounds
        let height = max(bounds.height, self.contentSize.height) + 200

        // Set the regular fill
        context?.setFillColor(self.gutterBackgroundColor.cgColor)
        context?.fill(CGRect.init(x: bounds.origin.x, y: bounds.origin.y, width: self.lineNumberLayoutManager!.gutterWidth, height: height))

        // Draw line
        context?.setFillColor(self.gutterLineColor.cgColor)
        context?.fill(CGRect.init(x: self.lineNumberLayoutManager!.gutterWidth, y: bounds.origin.y, width: 0.5, height: height))

        if lineCursorEnabled {
            self.lineNumberLayoutManager!.selectedRange = self.selectedRange

            var glyphRange = (self.lineNumberLayoutManager!.textStorage!.string as NSString).paragraphRange(for: self.selectedRange)
            glyphRange = self.lineNumberLayoutManager!.glyphRange(forCharacterRange: glyphRange, actualCharacterRange: nil)
            self.lineNumberLayoutManager?.selectedRange = glyphRange
            self.lineNumberLayoutManager?.invalidateDisplay(forGlyphRange: glyphRange)
        }

        super.draw(rect)
    }
    
    deinit {
        NSStringFromSelector(#selector(setter: font))
        NSStringFromSelector(#selector(setter: textColor))
        NSStringFromSelector(#selector(setter: selectedTextRange))
        NSStringFromSelector(#selector(setter: selectedRange))

        NotificationCenter.default.removeObserver(self)
    }

}

protocol CNTextViewDelegate{
    func textDidChanged(_ text:String)
}
