extension TableNavigator {
    public struct NavigationRequest {
        public let intent: FocusIntent
        public let invocation: Invocation
    }
}

extension TableNavigator.NavigationRequest {
    public enum Invocation {
        case keyCommand(KeyCommandDescriptor)
    }
}
