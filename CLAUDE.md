# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Building and Testing

- `swift build` - Build the package
- `swift test` - Run all tests
- `swift package resolve` - Resolve dependencies

## Architecture Overview

This is a Swift Package Manager library for displaying toast notifications in SwiftUI apps using The Composable Architecture (TCA). The library is part of the Indigo Stack ecosystem.

### Core Components

1. **ToastConfig** (`ToastConfig.swift`) - Data model defining toast content, level, duration, and optional button
2. **ToastLevel** (`ToastLevel.swift`) - Enum for toast severity levels (info, success, error, warning)
3. **ToastFeature** (`ToastFeature.swift`) - TCA reducer for individual toast behavior and the SwiftUI `ToastView` component
4. **ToastQueue** (`ToastQueue.swift`) - TCA reducer managing the queue of toasts, handling timing and transitions
5. **ToastQueueModifier** (`ToastQueueModifier.swift`) - SwiftUI view modifier that overlays toasts on existing views

### Key Dependencies

- **swift-composable-architecture** (1.20.2+) - State management and architecture
- **swift-collections** - Uses `DequeModule` for efficient queue operations

### Architecture Pattern

The library follows TCA patterns:

- State is managed through `@ObservableState` structs
- Actions are handled through `@Reducer` protocols
- The `ToastQueue` uses a `Deque<ToastConfig>` to manage pending toasts
- Individual toasts are scoped using `ToastFeature` reducers
- SwiftUI integration through view modifiers and stores

### Platform Support

- macOS 14+
- iOS 17+
- watchOS 10+
- tvOS 17+

### Integration Pattern

Apps integrate by:

1. Adding `ToastQueue.State` to their app state
2. Adding `ToastQueue.Action` to their app actions
3. Scoping the `ToastQueue` reducer in their app reducer
4. Using the `.toast()` modifier in their SwiftUI views
5. Sending `.addToQueue(ToastConfig)` actions to display toasts

### Testing

This library uses Swift Testing. Check @.agent/swift-testing.md for details on how to write tests.
