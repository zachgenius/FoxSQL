public struct KeyCommandDescriptor {
    public let input: Input
    public let modifiers: Modifiers
    
    public init(input: Input, modifiers: Modifiers) {
        self.input = input
        self.modifiers = modifiers
    }
    
    public var discoverabilityTitle: String?
}

extension KeyCommandDescriptor : Equatable {
    public static func ==(lhs: KeyCommandDescriptor, rhs: KeyCommandDescriptor) -> Bool {
        return lhs.input == rhs.input && lhs.modifiers == rhs.modifiers && lhs.discoverabilityTitle == rhs.discoverabilityTitle
    }
}

extension KeyCommandDescriptor : Hashable {
    public var hashValue: Int {
        return self.input.hashValue ^ self.modifiers.hashValue
    }
}
