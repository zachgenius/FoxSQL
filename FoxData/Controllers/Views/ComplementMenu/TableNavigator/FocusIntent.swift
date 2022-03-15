import UIKit

extension TableNavigator {
    public enum FocusIntent : Equatable {
        case initialRow
        case nextRow(afterRowAt: IndexPath)
        case previousRow(beforeRowAt: IndexPath)
        
        public static func ==(lhs: FocusIntent, rhs: FocusIntent) -> Bool {
            switch (lhs, rhs) {
                case (.initialRow, .initialRow): return true
                case (.nextRow(afterRowAt: let a), .nextRow(afterRowAt: let b)): return a == b
                case (.previousRow(beforeRowAt: let a), .previousRow(beforeRowAt: let b)): return a == b
                default: return false
            }
        }
    }
}
