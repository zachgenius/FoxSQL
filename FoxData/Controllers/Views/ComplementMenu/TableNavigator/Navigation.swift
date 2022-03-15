import UIKit

extension TableNavigator {
    public struct Navigation {
        public let indexPathForFocusedRow: IndexPath?
        
        public var scrollBehavior: ScrollBehavior = .none
        
        public init(focusingRowAt indexPath: IndexPath?, scrollBehavior: ScrollBehavior) {
            self.indexPathForFocusedRow = indexPath
            self.scrollBehavior = scrollBehavior
        }
    }
}

extension TableNavigator.Navigation {
    public enum ScrollBehavior {
        case none
        case scrollRectToVisible(CGRect, animated: Bool)
    }
}

extension TableNavigator.Navigation {
    public init(focusingRowAt indexPath: IndexPath?, scrollingTo rect: CGRect) {
        self.indexPathForFocusedRow = indexPath
        self.scrollBehavior = .scrollRectToVisible(rect, animated: false)
    }
}
