import ComposableArchitecture
import DequeModule
import SwiftUI

@Reducer
public struct ToastQueue {
  @Dependency(\.continuousClock) var clock

  public init() {}

  @ObservableState
  public struct State: Equatable, Sendable {
    public var queued: Deque<ToastConfig> = []
    public var currentToast: ToastFeature.State?

    public init(
      toasts: [ToastConfig] = [],
      currentToast: ToastFeature.State? = nil
    ) {
      self.queued = .init(toasts)
      self.currentToast = currentToast
    }
  }

  public enum Action: Equatable, Sendable, BindableAction {
    case addToQueue(ToastConfig)
    case dequeue
    case dismissCurrent
    case removeFromQueue(ToastConfig.ID)
    case userTappedButton(ToastConfig.ID)
    case binding(BindingAction<State>)

    case currentToast(ToastFeature.Action)
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce<State, Action> { state, action in
      switch action {
      case .addToQueue(let toast):
        state.queued.append(toast)
        return .send(.dequeue)

      case .dismissCurrent:
        state.currentToast = nil

        return .merge(
          .run { [clock] send in
            try await clock.sleep(for: .seconds(1))
            await send(.dequeue)
          },
          .cancel(id: state.currentToast?.config.id)
        )

      case .dequeue:
        guard
          state.currentToast == nil,
          let nextToastData = state.queued.popFirst()
        else {
          return .none
        }

        state.currentToast = .init(config: nextToastData)

        return .run { [clock] send in
          try await clock.sleep(for: .seconds(nextToastData.duration))
          await send(.dismissCurrent)
        }

      case .removeFromQueue(let toastID):
        state.queued.removeAll { $0.id == toastID }
        return .none

      case .currentToast(.buttonTapped):
        if let currentId = state.currentToast?.config.id {
          return .run { send in
            await withThrowingTaskGroup(of: Void.self) { group in
              group.addTask {
                await send(.dismissCurrent)
              }

              group.addTask {
                await send(.userTappedButton(currentId))
              }
            }
          }
        } else {
          return .send(.dismissCurrent)
        }

      case .currentToast(.toastTapped):
        return .send(.dismissCurrent)

      case .userTappedButton,
        .binding,
        .currentToast:
        return .none
      }
    }
    .ifLet(\.currentToast, action: \.currentToast) {
      ToastFeature()
    }
  }
}

#Preview {
  VStack {
    Text("This view has a toast displayed")
      .foregroundStyle(Color.white)
  }
  .padding()
  .containerRelativeFrame([.vertical, .horizontal])
  .background(
    LinearGradient(
      gradient: Gradient(colors: [.blue, .purple]),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    ),
    ignoresSafeAreaEdges: .all
  )
  .toast(
    .init(
      initialState: .init(
        currentToast: .init(
          config: .init(
            title: "Toasted!",
            subtitle: "This is a fresh toast",
            level: .info
          )
        )
      )
    ) {
      ToastQueue()
    }
  )
}
