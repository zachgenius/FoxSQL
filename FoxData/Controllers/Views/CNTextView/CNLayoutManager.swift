//
// Created by Zach Wang on 2019-02-02.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

class CNLayoutManager : NSLayoutManager {


    var lineNumberFont = UIFont.systemFont(ofSize: 12)
    var lineNumberColor = UIColor.gray
    var selectedLineNumberColor:UIColor = UIColor.init(white: 0.9, alpha: 1)

    var gutterWidth:CGFloat = 0
    var selectedRange:NSRange = NSRange()

    private let kMinimumGutterWidth:CGFloat = 46

    private var lineAreaInset:UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 4)

    private var lastParaLocation = 0
    private var lastParaNumber = 0

    override init() {
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup(){
        self.gutterWidth = kMinimumGutterWidth
    }

    /// MARK - Convinience
    func paragraphRectForRange(_ range: NSRange) -> CGRect{
        var theRange = (textStorage!.string as NSString).paragraphRange(for: range)
        theRange = self.glyphRange(forCharacterRange: theRange, actualCharacterRange: nil)

        let startRect = lineFragmentRect(forGlyphAt: theRange.location, effectiveRange: nil)
        let endRect = lineFragmentRect(forGlyphAt: theRange.location + theRange.length - 1, effectiveRange: nil)

        let paragraphRectForRange = startRect.union(endRect).offsetBy(dx: gutterWidth, dy: 8)
        return paragraphRectForRange
    }

    private func _paraNumberForRange(_ charRange:NSRange) -> Int{

        //  NSString does not provide a means of efficiently determining the paragraph number of a range of text.  This code
        //  attempts to optimize what would normally be a series linear searches by keeping track of the last paragraph number
        //  found and uses that as the starting point for next paragraph number search.  This works (mostly) because we
        //  are generally asked for continguous increasing sequences of paragraph numbers.  Also, this code is called in the
        //  course of drawing a pagefull of text, and so even when moving back, the number of paragraphs to search for is
        //  relativly low, even in really long bodies of text.
        //
        //  This all falls down when the user edits the text, and can potentially invalidate the cached paragraph number which
        //  causes a (potentially lengthy) search from the beginning of the string.
        if charRange.location == self.lastParaLocation{
            return self.lastParaNumber
        }

        //  We need to look backwards from the last known paragraph for the new paragraph range.  This generally happens
        //  when the text in the UITextView scrolls downward, revaling paragraphs before/above the ones previously drawn.
        else if charRange.location < self.lastParaLocation{
            let s = self.textStorage!.string as NSString
            var paraNumber = self.lastParaNumber
            s.enumerateSubstrings(in: NSRange.init(location:charRange.location, length: self.lastParaLocation - charRange.location),
                    options: [NSString.EnumerationOptions.byParagraphs, NSString.EnumerationOptions.substringNotRequired, NSString.EnumerationOptions.reverse])
            { subString, subStringRange, enclosingRange, stopPointer in
                if enclosingRange.location <= charRange.location{
                    stopPointer.pointee = true
                }

                paraNumber -= 1
            }

            self.lastParaLocation = charRange.location
            self.lastParaNumber = paraNumber
            return paraNumber
        }
        //  We need to look forward from the last known paragraph for the new paragraph range.  This generally happens
        //  when the text in the UITextView scrolls upwards, revealing paragraphs that follow the ones previously drawn.
        else {
            let s = self.textStorage!.string as NSString
            var paraNumber = self.lastParaNumber
            s.enumerateSubstrings(in: NSRange.init(location:self.lastParaLocation, length: charRange.location - self.lastParaLocation),
                    options: [NSString.EnumerationOptions.byParagraphs, NSString.EnumerationOptions.substringNotRequired, NSString.EnumerationOptions.reverse])
            { subString, subStringRange, enclosingRange, stopPointer in
                if enclosingRange.location > charRange.location{
                    stopPointer.pointee = true
                }

                paraNumber += 1
            }

            self.lastParaLocation = charRange.location
            self.lastParaNumber = paraNumber
            return paraNumber

        }

    }

    /// MARK - layout
    override func processEditing(for textStorage: NSTextStorage, edited editMask: NSTextStorage.EditActions, range newCharRange: NSRange, changeInLength delta: Int, invalidatedRange invalidatedCharRange: NSRange) {
        super.processEditing(for: textStorage, edited: editMask, range: newCharRange, changeInLength: delta, invalidatedRange: invalidatedCharRange)

        if invalidatedCharRange.location < self.lastParaLocation {
            //  When the backing store is edited ahead the cached paragraph location, invalidate the cache and force a complete
            //  recalculation.  We cannot be much smarter than this because we don't know how many paragraphs have been deleted
            //  since the text has already been removed from the backing store.
            self.lastParaLocation = 0;
            self.lastParaNumber = 0;
        }
    }

    /// MARK - drawing
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        //  Draw line numbers.  Note that the background for line number gutter is drawn by the LineNumberTextView class.
        let atts = [NSAttributedString.Key.font : self.lineNumberFont,
                    NSAttributedString.Key.foregroundColor : self.lineNumberColor]

        
        //TODO 最后新建的一行没有内容时不会显示行号
        var lastRect = CGRect()
        var paraNumber = 0

        self.enumerateLineFragments(forGlyphRange: glyphsToShow
        ) { rect, usedRect, textContainer, glyphRange, stopPointer in
            let charRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            let paraRange = (self.textStorage!.string as NSString).paragraphRange(for: charRange)
//            let showCursorRect = NSLocationInRange(self.selectedRange.location, paraRange)

            // TODO 显示当前行这块有点问题, 先隐藏
//            if showCursorRect{
//                let context = UIGraphicsGetCurrentContext()
//                let cursorRect = CGRect.init(x: 0, y: usedRect.origin.y + 8, width: self.gutterWidth, height: usedRect.height)
//                context?.setFillColor(self.selectedLineNumberColor.cgColor)
//                context?.fill(cursorRect)
//            }

            //   Only draw line numbers for the paragraph's first line fragment.  Subsequent fragments are wrapped portions of the paragraph and don't get the line number.
            if charRange.location == paraRange.location{
                let gutterRect = CGRect.init(x: 0, y: rect.origin.y, width: self.gutterWidth, height: rect.size.height).offsetBy(dx: origin.x, dy: origin.y)
                paraNumber = self._paraNumberForRange(charRange)
                let ln = NSString.init(format: "%ld", (paraNumber + 1))
                let size = ln.size(withAttributes: atts)
                ln.draw(in: gutterRect.offsetBy(dx: gutterRect.width - self.lineAreaInset.right - size.width - self.gutterWidth, dy: (gutterRect.height - size.height) / 2.0),
                        withAttributes: atts)
                lastRect = rect
            }
        }
        
//        //判断换行符来显示最后一行
//        if self.textStorage?.string.last == "\n"{
//            let gutterRect = CGRect.init(x: 0, y: lastRect.origin.y, width: self.gutterWidth, height: lastRect.size.height).offsetBy(dx: origin.x, dy: origin.y)
//            
//            //最后一行画当前行
//            let showCursorRect = self.selectedRange.location >= glyphsToShow.upperBound
//            if showCursorRect{
//                let context = UIGraphicsGetCurrentContext()
//                let cursorRect = CGRect.init(x: 0, y: gutterRect.origin.y + gutterRect.height, width: self.gutterWidth, height: gutterRect.height)
//                context?.setFillColor(self.selectedLineNumberColor.cgColor)
//                context?.fill(cursorRect)
//            }
//            
//
//            paraNumber = paraNumber + 1
//            let ln = NSString.init(format: "%ld", (paraNumber + 1))
//            let size = ln.size(withAttributes: atts)
//            let rect =  gutterRect.offsetBy(dx: gutterRect.width - self.lineAreaInset.right - size.width - self.gutterWidth, dy: gutterRect.height + (gutterRect.height - size.height) / 2.0)
//            ln.draw(in:rect,
//                    withAttributes: atts)
//        }
    }
}
