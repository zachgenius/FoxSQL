extension KeyCommandDescriptor {
    public enum Input {
        case characters(String)
        case upArrow
        case leftArrow
        case downArrow
        case rightArrow
        case escape
        
        public var isArrow: Bool {
            switch self {
                case .upArrow, .leftArrow, .downArrow, .rightArrow:
                    return true
                default: return false
            }
        }
    }
}

extension KeyCommandDescriptor.Input : Equatable {
    public static func ==(lhs: KeyCommandDescriptor.Input, rhs: KeyCommandDescriptor.Input) -> Bool {
        switch (lhs, rhs) {
            case (.characters(let a), .characters(let b)): return a == b
            case (.upArrow, .upArrow): return true
            case (.leftArrow, .leftArrow): return true
            case (.downArrow, .downArrow): return true
            case (.rightArrow, .rightArrow): return true
            case (.escape, .escape): return true
            default: return false
        }
    }
}

extension KeyCommandDescriptor.Input : Hashable {
    public var hashValue: Int {
        switch self {
            case .characters(let characters): return 6 + characters.hashValue
            case .upArrow: return 1
            case .leftArrow: return 2
            case .downArrow: return 3
            case .rightArrow: return 4
            case .escape: return 5
        }
    }
}
