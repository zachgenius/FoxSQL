import UIKit

extension TableNavigator {
    public struct FocusUpdate {
        public let indexPathForPreviouslyFocusedRow: IndexPath?
        public let indexPathForFocusedRow: IndexPath?
        
        public var isFocusedRowChanged: Bool {
            return self.indexPathForFocusedRow == self.indexPathForPreviouslyFocusedRow
        }
        
        public var indexPathsForChangedRows: [IndexPath] {
            if self.isFocusedRowChanged {
                return []
            } else {
                return [self.indexPathForPreviouslyFocusedRow, self.indexPathForFocusedRow].flatMap { $0 }
            }
        }
    }
}

extension TableNavigator.FocusUpdate {
    internal init(focusedRowAt indexPath: IndexPath?, previouslyFocusedRowAt previousIndexPath: IndexPath?) {
        self.indexPathForFocusedRow = indexPath
        self.indexPathForPreviouslyFocusedRow = previousIndexPath
    }
}
