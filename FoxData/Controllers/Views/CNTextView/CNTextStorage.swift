//
// Created by Zach Wang on 2019-02-02.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit

class CNTextStorage : NSTextStorage {
    private var _tokens:[CNToken] = []
    var tokens:[CNToken]{
        get {
            return _tokens
        }
        set {
            _tokens = newValue
            self.regularExpressionCache.removeAll()
            // Redraw all text
            self.update()
        }
    }
    var defaultFont:UIFont = UIFont.systemFont(ofSize: 14)
    var defaultTextColor:UIColor = UIColor.black

    private var attributedString = NSMutableAttributedString()
    private var regularExpressionCache:[String: NSRegularExpression] = [:]

    override var string: String {
        return attributedString.string
    }

    func update(){
        let range = NSMakeRange(0, self.length)
        let attributes = [NSAttributedString.Key.font:self.defaultFont, NSAttributedString.Key.foregroundColor:self.defaultTextColor]
        self.addAttributes(attributes, range: range)
        self.applyStyles(searchRange: range)
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [Key: Any] {
        return self.attributedString.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        self.beginEditing()
        self.attributedString.replaceCharacters(in: range, with: str)
        self.edited([.editedAttributes, .editedCharacters], range: range, changeInLength: str.count - range.length)
        self.endEditing()
    }

    override func setAttributes(_ attrs: [Key: Any]?, range: NSRange) {
        self.beginEditing()
        self.attributedString.setAttributes(attrs, range: range)
        self.edited(.editedAttributes, range: range, changeInLength: 0)
        self.endEditing()
    }

    override func processEditing() {
        self.performReplacementForRange(changedRange: self.editedRange)
        super.processEditing()
    }

    private func performReplacementForRange(changedRange:NSRange){
        let extendedRange = NSUnionRange(changedRange, (self.attributedString.string as NSString).lineRange(for: NSMakeRange(NSMaxRange(changedRange), 0)))
        self.applyStyles(searchRange: extendedRange)
    }

    private func applyStyles(searchRange:NSRange){
        if self.editedRange.location == NSNotFound{
            return
        }

        let paragraphRange = (self.string as NSString).paragraphRange(for: self.editedRange)

        // Reset the text attributes
        let attributes = [NSAttributedString.Key.font:self.defaultFont, NSAttributedString.Key.foregroundColor:self.defaultTextColor]
        self.setAttributes(attributes, range: paragraphRange)
        for item in _tokens {
            let regex = self.expressionForDefinition(definition: item.name)
            if regex != nil{
                regex!.enumerateMatches(in: self.string, options: .reportProgress, range: paragraphRange //TODO 确定option用哪个
                ) { result, flags, pointer in
                    for (attrName, value) in item.attributes {
                        self.addAttribute(attrName, value: value, range: result!.range)
                    }
                }
            }

        }
    }

    private func expressionForDefinition(definition:String) -> NSRegularExpression?{
        var attribute:CNToken?
        for item in _tokens {
            if item.name == definition{
                attribute = item
                break
            }
        }

        var expression:NSRegularExpression?
        if attribute != nil{
            expression = self.regularExpressionCache[attribute!.expression]
        }

        if expression == nil{
            do {
                expression = try NSRegularExpression.init(pattern: attribute!.expression, options: .caseInsensitive)
                self.regularExpressionCache[definition] = expression
            } catch {
            }
        }

        return expression
    }
}
