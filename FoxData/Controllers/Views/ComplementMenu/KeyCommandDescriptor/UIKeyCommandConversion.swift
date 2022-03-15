import UIKit

extension KeyCommandDescriptor {
    internal init(from uiKeyCommand: UIKeyCommand) {
        self.init(input: KeyCommandDescriptor.input(for: uiKeyCommand.input!), modifiers: KeyCommandDescriptor.modifiers(for: uiKeyCommand.modifierFlags))
        self.discoverabilityTitle = uiKeyCommand.discoverabilityTitle
    }
    
    internal func uiKeyCommand(withAction action: Selector) -> UIKeyCommand {
        let uiKeyCommand = UIKeyCommand(input: KeyCommandDescriptor.keyInput(for: self.input), modifierFlags: KeyCommandDescriptor.modifierFlags(for: self.modifiers), action: action)
        uiKeyCommand.discoverabilityTitle = self.discoverabilityTitle
        
        return uiKeyCommand
    }
}

extension KeyCommandDescriptor {
    private static func keyInput(for input: KeyCommandDescriptor.Input) -> String {
        let keyInput: String
        
        switch input {
            case .characters(let characters):
                keyInput = characters
            case .leftArrow:
                keyInput = UIKeyCommand.inputLeftArrow
            case .upArrow:
                keyInput = UIKeyCommand.inputUpArrow
            case .rightArrow:
                keyInput = UIKeyCommand.inputRightArrow
            case .downArrow:
                keyInput = UIKeyCommand.inputDownArrow
            case .escape:
                keyInput = UIKeyCommand.inputEscape
        }
        
        return keyInput
    }
    
    private static func input(for keyInput: String) -> KeyCommandDescriptor.Input {
        let input: KeyCommandDescriptor.Input
        
        switch keyInput {
        case UIKeyCommand.inputLeftArrow:
                input = .leftArrow
        case UIKeyCommand.inputUpArrow:
                input = .upArrow
        case UIKeyCommand.inputRightArrow:
                input = .rightArrow
        case UIKeyCommand.inputDownArrow:
                input = .downArrow
        case UIKeyCommand.inputEscape:
                input = .escape
            default:
                input = .characters(keyInput)
        }
        
        return input
    }
    
    private static let flagsForModifier: [KeyCommandDescriptor.Modifiers : UIKeyModifierFlags] = [.shift : .shift, .control : .control, .alternate : .alternate, .alphaShift: .alphaShift]

    private static func modifiers(for flags: UIKeyModifierFlags) -> KeyCommandDescriptor.Modifiers {
        var modifiers: KeyCommandDescriptor.Modifiers = []
        
        for (modifier, flag) in self.flagsForModifier {
            if flags.contains(flag) {
                modifiers.insert(modifier)
            }
        }
        
        return modifiers
    }
    
    private static func modifierFlags(for modifiers: KeyCommandDescriptor.Modifiers) -> UIKeyModifierFlags {
        var modifierFlags: UIKeyModifierFlags = []
        
        for (modifier, flag) in self.flagsForModifier {
            if modifiers.contains(modifier) {
                modifierFlags.insert(flag)
            }
        }
        
        return modifierFlags
    }
}
