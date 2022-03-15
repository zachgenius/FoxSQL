extension KeyCommandDescriptor {
    public struct Modifiers : OptionSet {
        public let rawValue: UInt
        
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    
        public static let command: Modifiers = Modifiers(rawValue: 1 << 1)
        public static let shift: Modifiers = Modifiers(rawValue: 1 << 2)
        public static let control: Modifiers = Modifiers(rawValue: 1 << 3)
        public static let alternate: Modifiers = Modifiers(rawValue: 1 << 4)
        public static let alphaShift: Modifiers = Modifiers(rawValue: 1 << 5) // caps lock
    }
}

extension KeyCommandDescriptor.Modifiers : Hashable {
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
}
