import UIKit

public protocol TableNavigatorDelegate : class {
    // Required
    func tableNavigator(_ navigator: TableNavigator, didUpdateFocus focusUpdate: TableNavigator.FocusUpdate, completedNavigationWith context: TableNavigator.NavigationCompletionContext)
    func tableNavigator(_ navigator: TableNavigator, commitFocusedRowAt indexPath: IndexPath)
    
    // Optional
    func tableNavigator(_ navigator: TableNavigator, keyCommandDescriptorsFor action: TableNavigator.Action, defaultDescriptors: [KeyCommandDescriptor]) -> [KeyCommandDescriptor]
    func tableNavigator(_ navigator: TableNavigator, navigationResponseFor request: TableNavigator.NavigationRequest) -> TableNavigator.NavigationResponse
}

// MARK: Default implementation for delegate methods
extension TableNavigatorDelegate {
    public func tableNavigator(_ navigator: TableNavigator, keyCommandDescriptorsFor action: TableNavigator.Action, defaultDescriptors: [KeyCommandDescriptor]) -> [KeyCommandDescriptor] {
        return defaultDescriptors
    }
    
    public func tableNavigator(_ navigator: TableNavigator, navigationResponseFor request: TableNavigator.NavigationRequest) -> TableNavigator.NavigationResponse {
        return .defaultNavigation
    }
}
