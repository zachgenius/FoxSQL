import UIKit

extension TableNavigator {
    public enum Action : Equatable {
        case changeFocus(for: FocusIntent)
        case commitFocusedRow(at: IndexPath)
        
        public static func ==(lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
                case (.changeFocus(for: let a), .changeFocus(for: let b)): return a == b
                case (.commitFocusedRow(at: let a), .commitFocusedRow(at: let b)): return a == b
                default: return false
            }
        }
    }
}
