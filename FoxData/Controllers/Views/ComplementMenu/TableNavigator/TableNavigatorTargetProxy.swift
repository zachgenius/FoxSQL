import UIKit

internal class TableNavigatorKeyCommandActionProxy : NSObject {
    public unowned let navigator: TableNavigator
    
    internal init(navigator: TableNavigator) {
        self.navigator = navigator
    }
    
    @objc internal func commitFocusedRowKeyCommandAction(_ sender: Any?) {
        self.navigator.performCommitFocusedRowKeyCommandAction(sender as! UIKeyCommand)
    }
    
    @objc internal func changeFocusToPreviousRowKeyCommandAction(_ sender: Any?) {
        self.navigator.performChangeFocusToPreviousRowKeyCommandAction(sender as! UIKeyCommand)
    }
    
    @objc internal func changeFocusToNextRowKeyCommandAction(_ sender: Any?) {
        self.navigator.performChangeFocusToNextRowKeyCommandAction(sender as! UIKeyCommand)
    }
    
    @objc internal func changeFocusToInitialRowKeyCommandAction(_ sender: Any?) {
        self.navigator.performChangeFocusToInitialRowKeyCommandAction(sender as! UIKeyCommand)
    }
}
