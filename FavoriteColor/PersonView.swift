//
//  PersonView.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import ComposableArchitecture
import SwiftUI

indirect enum NextPersonState: Equatable {
  case none
  case next(PersonState)
}

struct PersonState: Equatable {
  let personId: UUID
  var nextPersonState: NextPersonState = .none
}

extension BaseState where State == PersonState {
  var person: Person? {
    get {
      people[id: state.personId]
    }
    set {
      people[id: state.personId] = newValue
    }
  }

  var nextPersonFeatureState: BaseState<PersonState>? {
    get {
      switch state.nextPersonState {
      case .none:
        return nil
      case let .next(nextState):
        return .init(people: people, state: nextState)
      }
    }
    set {
      guard let nextPersonFeatureState = newValue else { return }
      people = nextPersonFeatureState.people
      state.nextPersonState = .next(nextPersonFeatureState.state)
    }
  }
}

indirect enum PersonAction: Equatable {
  case changeColor(Color)
  case loadNextPerson(UUID)
  case setPushingNextPerson(Bool)
  case nextPerson(PersonAction)
}

struct PersonEnvironment {}

extension PersonEnvironment {
  static var live = Self()
}

let PersonReducer = Reducer<
  BaseState<PersonState>,
  PersonAction,
  PersonEnvironment
>.recurse { `self`, state, action, environment in
  switch action {
  case let .changeColor(newColor):
    state.person?.color = newColor
    return .none
  case let .loadNextPerson(nextPersonId):
    state.nextPersonState = .next(.init(personId: nextPersonId))
    return .none
  case let .setPushingNextPerson(isPushing):
    if !isPushing {
      state.nextPersonState = .none
    }
    return .none
  case .nextPerson:
    return self.optional().pullback(
      state: \.nextPersonFeatureState,
      action: /PersonAction.nextPerson,
      environment: { $0 }
    )
    .run(&state, action, environment)
  }
}

struct PersonView: View {
  typealias ViewStoreType = ViewStore<BaseState<PersonState>, PersonAction>
  let store: Store<BaseState<PersonState>, PersonAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      VStack(spacing: 8) {
        buildColor(viewStore)
        Divider()
        buildChangeColor(viewStore)
        buildParentStack(viewStore)
        buildChildrenStack(viewStore)
        buildNavigationLink(viewStore)
      }
      .navigationTitle(viewStore.person?.name ?? "")
    }
  }

  @ViewBuilder
  private func buildColor(_ viewStore: ViewStoreType) -> some View {
    if let color = viewStore.person?.color {
      color
        .frame(width: 100, height: 100)
        .cornerRadius(16)
        .padding()
    }
  }

  @ViewBuilder
  private func buildChangeColor(_ viewStore: ViewStoreType) -> some View {
    HStack {
      Text("Change Color:")

      ForEach([Color.blue, .green, .yellow, .red], id: \.self) { color in
        Button {
          viewStore.send(.changeColor(color))
        } label: {
          color
            .frame(width: 16, height: 16)
            .cornerRadius(4)
        }
      }
    }
  }

  @ViewBuilder
  private func buildParentStack(_ viewStore: ViewStoreType) -> some View {
    if let parentId = viewStore.person?.parentId,
       let parent = viewStore.people[id: parentId] {
      HStack {
        Text("Parent:")
        Button(parent.name) {
          viewStore.send(.loadNextPerson(parentId))
        }
      }
    }
  }

  @ViewBuilder
  private func buildChildrenStack(_ viewStore: ViewStoreType) -> some View {
    if let childrenIds = viewStore.person?.childrenIds, !childrenIds.isEmpty {
      HStack {
        Text("Children:")

        ForEach(childrenIds, id: \.self) { childId in
          if let child = viewStore.people[id: childId] {
            Button(child.name) {
              viewStore.send(.loadNextPerson(childId))
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private func buildNavigationLink(_ viewStore: ViewStoreType) -> some View {
    NavigationLink(isActive: viewStore.binding(
      get: { $0.nextPersonState != .none },
      send: PersonAction.setPushingNextPerson
    )) {
      IfLetStore(
        store.scope(
          state: \.nextPersonFeatureState,
          action: PersonAction.nextPerson
        ),
        then: PersonView.init
      )
    } label: {
      EmptyView()
    }
  }
}

#if DEBUG
  struct PersonView_Previews: PreviewProvider {
    static let id = UUID()
    static let person = Person(
      id: myUUID,
      name: "Me",
      color: .green,
      parentId: nil,
      childrenIds: []
    )

    static var previews: some View {
      NavigationView {
        PersonView(
          store: .init(
            initialState: .init(
              people: [person],
              state: .init(personId: id)
            ),
            reducer: PersonReducer,
            environment: .live
          )
        )
      }
    }
  }
#endif

extension Reducer {
  static func recurse(
    _ reducer: @escaping (Reducer, inout State, Action, Environment) -> Effect<Action, Never>
  ) -> Reducer {
    var `self`: Reducer!
    self = Reducer { state, action, environment in
      reducer(self, &state, action, environment)
    }
    return self
  }
}
