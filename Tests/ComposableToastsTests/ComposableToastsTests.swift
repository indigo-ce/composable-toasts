import ComposableArchitecture
import Foundation
import Testing

@testable import ComposableToasts

@Suite("Toast Configuration Tests")
struct ToastConfigTests {
  @Test("Creates toast with default values")
  func createsWithDefaults() {
    let toast = ToastConfig(title: "Test", level: .info)

    #expect(toast.title == "Test")
    #expect(toast.level == .info)
    #expect(toast.subtitle == nil)
    #expect(toast.duration == 4)
    #expect(toast.buttonLabel == nil)
    #expect(toast.id != UUID())
  }

  @Test("Creates toast with custom values")
  func createsWithCustomValues() {
    let id = UUID()
    let toast = ToastConfig(
      id: id,
      title: "Custom Toast",
      subtitle: "With subtitle",
      level: .error,
      duration: 10,
      buttonLabel: "Action"
    )

    #expect(toast.id == id)
    #expect(toast.title == "Custom Toast")
    #expect(toast.subtitle == "With subtitle")
    #expect(toast.level == .error)
    #expect(toast.duration == 10)
    #expect(toast.buttonLabel == "Action")
  }

  @Test("Toast configs are equatable")
  func toastConfigsAreEquatable() {
    let id = UUID()
    let toast1 = ToastConfig(id: id, title: "Test", level: .info)
    let toast2 = ToastConfig(id: id, title: "Test", level: .info)
    let toast3 = ToastConfig(title: "Different", level: .info)

    #expect(toast1 == toast2)
    #expect(toast1 != toast3)
  }

  @Test("Toast configs are hashable")
  func toastConfigsAreHashable() {
    let toast1 = ToastConfig(title: "Test", level: .info)
    let toast2 = ToastConfig(title: "Test", level: .error)

    let set: Set<ToastConfig> = [toast1, toast2]
    #expect(set.count == 2)
  }
}

@Suite("Toast Level Tests")
struct ToastLevelTests {
  @Test(
    "All toast levels are available",
    arguments: [
      ToastLevel.info,
      ToastLevel.success,
      ToastLevel.error,
      ToastLevel.warning,
    ])
  func allLevelsExist(_ level: ToastLevel) {
    #expect(level == level)
  }

  @Test("Toast levels are equatable")
  func levelsAreEquatable() {
    #expect(ToastLevel.info == .info)
    #expect(ToastLevel.success != .error)
    #expect(ToastLevel.warning != .info)
  }
}

@Suite("Toast Feature Tests")
struct ToastFeatureTests {
  @Test("Creates initial state with config")
  func createsInitialState() {
    let config = ToastConfig(title: "Test", level: .info)
    let state = ToastFeature.State(config: config)

    #expect(state.config == config)
  }

  @Test("Has correct action types")
  func hasCorrectActions() {
    let buttonAction = ToastFeature.Action.buttonTapped
    let toastAction = ToastFeature.Action.toastTapped

    #expect(buttonAction == .buttonTapped)
    #expect(toastAction == .toastTapped)
    #expect(buttonAction != toastAction)
  }
}

@Suite("Toast Queue Tests")
struct ToastQueueTests {
  @Test("Creates empty queue by default")
  func createsEmptyQueue() {
    let state = ToastQueue.State()

    #expect(state.queued.isEmpty)
    #expect(state.currentToast == nil)
  }

  @Test("Creates queue with initial toasts")
  func createsQueueWithToasts() {
    let toast1 = ToastConfig(title: "First", level: .info)
    let toast2 = ToastConfig(title: "Second", level: .error)
    let state = ToastQueue.State(toasts: [toast1, toast2])

    #expect(state.queued.count == 2)
    #expect(state.queued.first == toast1)
    #expect(state.queued.last == toast2)
  }

  @Test("Creates queue with current toast")
  func createsQueueWithCurrentToast() {
    let config = ToastConfig(title: "Current", level: .success)
    let currentToast = ToastFeature.State(config: config)
    let state = ToastQueue.State(currentToast: currentToast)

    #expect(state.currentToast?.config == config)
  }

  @Test("Adding toast to queue")
  func addingToastToQueue() async {
    let store = await TestStore(initialState: ToastQueue.State()) {
      ToastQueue()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    let toast = ToastConfig(title: "Test", level: .info, duration: 0)

    await store.send(.addToQueue(toast)) {
      $0.queued.append(toast)
    }

    await store.receive(.dequeue) {
      $0.currentToast = ToastFeature.State(config: toast)
      $0.queued.removeFirst()
    }

    await store.receive(.dismissCurrent) {
      $0.currentToast = nil
    }

    await store.receive(.dequeue)
    await store.finish()
  }

  @Test("Dismissing current toast")
  func dismissingCurrentToast() async {
    let config = ToastConfig(title: "Test", level: .info)
    let initialState = ToastQueue.State(
      currentToast: ToastFeature.State(config: config)
    )

    let store = await TestStore(initialState: initialState) {
      ToastQueue()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.dismissCurrent) {
      $0.currentToast = nil
    }

    await store.receive(.dequeue)
    await store.finish()
  }

  @Test("Removing toast from queue")
  func removingToastFromQueue() async {
    let toast1 = ToastConfig(title: "First", level: .info)
    let toast2 = ToastConfig(title: "Second", level: .error)
    let initialState = ToastQueue.State(toasts: [toast1, toast2])

    let store = await TestStore(initialState: initialState) {
      ToastQueue()
    }

    await store.send(.removeFromQueue(toast1.id)) {
      $0.queued.removeAll { $0.id == toast1.id }
    }

    #expect(await store.state.queued.count == 1)
    #expect(await store.state.queued.first == toast2)
  }

  @Test("Toast button tapped triggers dismiss and user action")
  func toastButtonTapped() async {
    let config = ToastConfig(title: "Test", level: .info, buttonLabel: "Action")
    let initialState = ToastQueue.State(
      currentToast: ToastFeature.State(config: config)
    )

    let store = await TestStore(initialState: initialState) {
      ToastQueue()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.currentToast(.buttonTapped))
    await store.receive(.dismissCurrent) {
      $0.currentToast = nil
    }
    await store.receive(.userTappedButton(config.id))
    await store.receive(.dequeue)
    await store.finish()
  }

  @Test("Toast tapped triggers dismiss")
  func toastTapped() async {
    let config = ToastConfig(title: "Test", level: .info)
    let initialState = ToastQueue.State(
      currentToast: ToastFeature.State(config: config)
    )

    let store = await TestStore(initialState: initialState) {
      ToastQueue()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.currentToast(.toastTapped))
    await store.receive(.dismissCurrent) {
      $0.currentToast = nil
    }
    await store.receive(.dequeue)
    await store.finish()
  }

  @Test("Dequeue does nothing when toast is already showing")
  func dequeueWithCurrentToast() async {
    let config = ToastConfig(title: "Current", level: .info)
    let queuedToast = ToastConfig(title: "Queued", level: .error)
    let initialState = ToastQueue.State(
      toasts: [queuedToast],
      currentToast: ToastFeature.State(config: config)
    )

    let store = await TestStore(initialState: initialState) {
      ToastQueue()
    }

    await store.send(.dequeue)

    #expect(await store.state.currentToast?.config == config)
    #expect(await store.state.queued.count == 1)
  }

  @Test("Dequeue does nothing when queue is empty")
  func dequeueEmptyQueue() async {
    let store = await TestStore(initialState: ToastQueue.State()) {
      ToastQueue()
    }

    await store.send(.dequeue)

    #expect(await store.state.currentToast == nil)
    #expect(await store.state.queued.isEmpty)
  }
}
