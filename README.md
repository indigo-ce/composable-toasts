# 🪻 composable-toasts

A library to queue and display toasts using SwiftUI and The Composable
Architecture. It is part of the [Indigo Stack](https://indigostack.org).

## Usage

```swift
import ComposableToasts

// In your feature state
@ObservableState
struct State: Equatable, Sendable {
  var toastQueue: ToastQueue.State = .init()
  // ...
}

// In your feature action
enum Action: Equatable, Sendable {
  case toastQueue(ToastQueue.Action)
  // ...
}

// In your reducer body
var body: some ReducerOf<Self> {
  Scope(state: \.toastQueue, action: \.toastQueue) {
    ToastQueue()
  }
}

// In your view body
.toast(
  store.scope(state: \.toastQueue, action: \.toastQueue)
)
```

To queue a toast, call the `addToQueue` action with a `ToastConfig`:

```swift
let toast = ToastConfig(
  id: UUID(),
  title: "The Toastening",
  level: .info,
)

return .send(.toastQueue(.addToQueue(toastData)))
```

You can control other aspects of the toast queues, such as dismissing the
current using `dismissCurrent`, or removing a toast from the queue using
`removeFromQueue`.

When the toast button is tapped, the `userTappedButton` action is sent with the
ID of the toast that was tapped.

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for
details.
