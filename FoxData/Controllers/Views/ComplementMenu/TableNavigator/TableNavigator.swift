import UIKit

public class TableNavigator {
    public weak var delegate: TableNavigatorDelegate!
    public unowned let tableView: UITableView
    
    private var keyCommandActionProxy: TableNavigatorKeyCommandActionProxy!
    
    public private(set) var indexPathForFocusedRow: IndexPath? {
        didSet {
            self.invalidatePossibleActions()
        }
    }
    
    private var _possibleActions: [Action]?
    
    public init(tableView: UITableView, delegate: TableNavigatorDelegate) {
        self.tableView = tableView
        self.delegate = delegate
        
        self.keyCommandActionProxy = TableNavigatorKeyCommandActionProxy(navigator: self)
    }
    
    // Call this to remove any focus on a table view. This is necessary if table view data updates invalidate the `indexPathForFocusedRow`. It may also be desirable to call this to improve user experience in certain UI situations. The returned `FocusUpdate` provides information about focus changes, if any.
    @discardableResult public func removeFocus() -> FocusUpdate {
        let update = FocusUpdate(focusedRowAt: nil, previouslyFocusedRowAt: self.indexPathForFocusedRow)
        
        self.indexPathForFocusedRow = nil
        
        return update
    }
}

// MARK: Responder chain provider methods. Typicaly called from parent view controller.
extension TableNavigator {
    public var possibleKeyCommands: [UIKeyCommand] {
        let keyCommands = self.possibleActions.map { self.keyCommands(for: $0) }.joined()
        
        return Array(keyCommands)
    }
    
    public func target(forKeyCommandAction action: Selector) -> Any? {
        let canPerformAction = self.possibleActions.contains(where: { actionType in
            return self.keyCommandSelector(for: actionType) == action
        })
        
        return canPerformAction ? self.keyCommandActionProxy : nil
    }
}

// MARK: UIKeyCommand action methods
extension TableNavigator {
    internal func performCommitFocusedRowKeyCommandAction(_ keyCommand: UIKeyCommand) {
        if let indexPath = self.indexPathForFocusedRow, let action = self.possibleAction(matching: self.predicateForPossibleAction(equalTo: .commitFocusedRow(at: indexPath))) {
            self.perform(action, for: keyCommand)
        }
    }
    
    internal func performChangeFocusToPreviousRowKeyCommandAction(_ keyCommand: UIKeyCommand) {
        if let indexPath = self.indexPathForFocusedRow, let action = self.possibleAction(matching: self.predicateForNavigationPossibleAction(with: .previousRow(beforeRowAt: indexPath))) {
            self.perform(action, for: keyCommand)
        }
    }
    
    internal func performChangeFocusToNextRowKeyCommandAction(_ keyCommand: UIKeyCommand) {
        if let indexPath = self.indexPathForFocusedRow, let action = self.possibleAction(matching: self.predicateForNavigationPossibleAction(with: .nextRow(afterRowAt: indexPath))) {
            self.perform(action, for: keyCommand)
        }
    }
    
    internal func performChangeFocusToInitialRowKeyCommandAction(_ keyCommand: UIKeyCommand) {
        if self.indexPathForFocusedRow == nil, let action = self.possibleAction(matching: self.predicateForNavigationPossibleAction(with: .initialRow)) {
            self.perform(action, for: keyCommand)
        }
    }
}

// MARK: Internal actions and focus state effects
extension TableNavigator {
    private func commitFocusedRow(at indexPath: IndexPath) {
        self.delegate.tableNavigator(self, commitFocusedRowAt: indexPath)
    }
    
    private func respond(to request: NavigationRequest) {
        let response = self.response(for: request)
        
        let navigation: Navigation?
        
        switch response {
            case .noNavigation:
                navigation = nil
            case .defaultNavigation:
                navigation = self.defaultNavigation(for: request)
            case .navigate(let custom):
                navigation = custom
        }
        
        if let navigation = navigation {
            let previous = self.indexPathForFocusedRow
            let new = navigation.indexPathForFocusedRow

            self.indexPathForFocusedRow = new

            switch navigation.scrollBehavior {
                case .none:
                    break
                case .scrollRectToVisible(let visibleRect, animated: let animated):
                    self.tableView.scrollRectToVisible(visibleRect, animated: animated)
            }
        
            let focusUpdate = FocusUpdate(focusedRowAt: new, previouslyFocusedRowAt: previous)

            let context = TableNavigator.NavigationCompletionContext(navigation: navigation, request: request)

            self.delegate.tableNavigator(self, didUpdateFocus: focusUpdate, completedNavigationWith: context)
        }
    }
    
    private func perform(_ action: Action, for keyCommand: UIKeyCommand) {
        switch action {
            case .commitFocusedRow(at: let indexPath):
                self.commitFocusedRow(at: indexPath)
            case .changeFocus(for: let intent):
                let request = NavigationRequest(intent: intent, invocation: .keyCommand(KeyCommandDescriptor(from: keyCommand)))
                
                self.respond(to: request)
        }
    }
    
    private var possibleActions: [Action] {
        if let possibleActions = self._possibleActions {
            return possibleActions
        }
        
        let actions = self.makePossibleActions()
        self._possibleActions = actions
        
        return actions
    }
    
    private func invalidatePossibleActions() {
        self._possibleActions = nil
    }
    
    private func makePossibleActions() -> [Action] {
        var possibleActions = [Action]()
        
        let availableIntents: [FocusIntent]
        
        if let indexPathForFocusedRow = self.indexPathForFocusedRow {
            possibleActions.append(.commitFocusedRow(at: indexPathForFocusedRow))
            
            availableIntents = [.previousRow(beforeRowAt: indexPathForFocusedRow), .nextRow(afterRowAt: indexPathForFocusedRow)]
        } else {
            availableIntents = [.initialRow]
        }
        
        for intent in availableIntents {
            possibleActions.append(.changeFocus(for: intent))
        }
        
        return possibleActions
    }
    
    private func possibleAction(matching predicate: PossibleActionPredicate) -> Action? {
        for action in self.possibleActions {
            if predicate(action) {
                return action
            }
        }
        
        return nil
    }
    
    private typealias PossibleActionPredicate = (Action) -> Bool
    
    private func predicateForPossibleAction(equalTo other: Action) -> PossibleActionPredicate {
        return { action in
            action == other
        }
    }
    
    private func predicateForNavigationPossibleAction(with intent: FocusIntent) -> PossibleActionPredicate {
        return { action in
            switch action {
                case .changeFocus(for: let candidateIntent):
                    return intent == candidateIntent
                case .commitFocusedRow(at: _):
                    return false
            }
        }
    }
}

// MARK: KeyCommand configuration and creation
extension TableNavigator {
    private func keyCommands(for action: Action) -> [UIKeyCommand] {
        let descriptors = self.delegate.tableNavigator(self, keyCommandDescriptorsFor: action, defaultDescriptors: self.defaultKeyCommandDescriptors(for: action))
        
        return descriptors.map { descriptor in
            return descriptor.uiKeyCommand(withAction: self.keyCommandSelector(for: action))
        }
    }
    
    private func keyCommandSelector(for action: Action) -> Selector {
        switch action {
            case .changeFocus(for: .initialRow):
                return #selector(TableNavigatorKeyCommandActionProxy.changeFocusToInitialRowKeyCommandAction(_:))
            case .changeFocus(for: .previousRow(beforeRowAt: _)):
                return #selector(TableNavigatorKeyCommandActionProxy.changeFocusToPreviousRowKeyCommandAction(_:))
            case .changeFocus(for: .nextRow(afterRowAt: _)):
                return #selector(TableNavigatorKeyCommandActionProxy.changeFocusToNextRowKeyCommandAction(_:))
            case .commitFocusedRow(at: _):
                return #selector(TableNavigatorKeyCommandActionProxy.commitFocusedRowKeyCommandAction(_:))
        }
    }
    
    private func defaultKeyCommandDescriptors(for action: Action) -> [KeyCommandDescriptor] {
        let descriptors: [KeyCommandDescriptor]
        
        switch action {
            case .changeFocus(for: .initialRow), .changeFocus(for: .nextRow(afterRowAt: _)):
                descriptors = [KeyCommandDescriptor(input: .downArrow, modifiers: [])]
            case .changeFocus(for: .previousRow(beforeRowAt: _)):
                descriptors = [KeyCommandDescriptor(input: .upArrow, modifiers: [])]
            case .commitFocusedRow(at: _):
                descriptors = [KeyCommandDescriptor(input: .rightArrow, modifiers: []), KeyCommandDescriptor(input: .characters("\r"), modifiers: [])]
        }
        
        return descriptors
    }
}

// MARK: Navigation response acessors.
extension TableNavigator {
    private func defaultNavigation(for request: NavigationRequest) -> Navigation? {
        let indexPathForFocusedRow: IndexPath?
        
        switch request.intent {
            case .initialRow:
                indexPathForFocusedRow = self.tableView.indexPathForFirstRow
            case .nextRow(afterRowAt: let indexPath):
                indexPathForFocusedRow = self.tableView.indexPathForRow(startingAt: indexPath, offsetBy: 1)
            case .previousRow(beforeRowAt: let indexPath):
                indexPathForFocusedRow = self.tableView.indexPathForRow(startingAt: indexPath, offsetBy: -1)
        }
        
        return indexPathForFocusedRow.map { indexPath in
            let visibleRect = self.tableView.rectForRow(at: indexPath)
            
            let navigation = Navigation(focusingRowAt: indexPath, scrollingTo: visibleRect)
            
            return navigation
        } ?? nil
    }
    
    private func response(for request: NavigationRequest) -> NavigationResponse {
        return self.delegate.tableNavigator(self, navigationResponseFor: request)
    }
}

