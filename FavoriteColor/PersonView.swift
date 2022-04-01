//
//  PersonView.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import ComposableArchitecture
import SwiftUI

struct PersonViewState: Equatable, Identifiable {
  let id: UUID
  var nextId: UUID?
  var parentViewStates: IdentifiedArrayOf<PersonViewState> = []
  var childrenViewStates: IdentifiedArrayOf<PersonViewState> = []
}

struct PersonState: Equatable, Identifiable {
  var shared: SharedData
  var viewState: PersonViewState

  var id: UUID { viewState.id }

  var person: Person? {
    get {
      shared.people[id]
    }
    set {
      shared.people[id] = newValue
    }
  }

  var parentStates: IdentifiedArrayOf<PersonState> {
    get {
      IdentifiedArray(uniqueElements: person?.parentIds.compactMap { parentId -> PersonState? in
        let parentViewState = viewState.parentViewStates[id: parentId] ?? .init(id: parentId)
        return .init(shared: shared, viewState: parentViewState)
      } ?? [])
    }
    set {
      // update states only from pushed next person
      guard let nextId = viewState.nextId,
            let nextPerson = newValue[id: nextId] else {
        return
      }
      shared = nextPerson.shared
      viewState.parentViewStates[id: nextId] = nextPerson.viewState
    }
  }

  var childrenStates: IdentifiedArrayOf<PersonState> {
    get {
      IdentifiedArray(uniqueElements: person?.childrenIds.compactMap { childId -> PersonState? in
        let childViewState = viewState.childrenViewStates[id: childId] ?? .init(id: childId)
        return .init(shared: shared, viewState: childViewState)
      } ?? [])
    }
    set {
      // update states only from pushed next person
      guard let nextId = viewState.nextId,
            let nextPerson = newValue[id: nextId] else {
        return
      }
      shared = nextPerson.shared
      viewState.childrenViewStates[id: nextId] = nextPerson.viewState
    }
  }
}

indirect enum PersonAction: Equatable {
  case changeColor(Color)
  case pushToNextPerson(UUID, Bool)
  case nextParent(UUID, PersonAction)
  case nextChild(UUID, PersonAction)
}

struct PersonEnvironment {}

extension PersonEnvironment {
  static var live = Self()
}

let PersonReducer = Reducer<
  PersonState,
  PersonAction,
  PersonEnvironment
>.recurse { `self`, state, action, environment in
  switch action {
  case let .changeColor(newColor):
    state.person?.color = newColor
    return .none
  case let .pushToNextPerson(nextId, isPushing):
    state.viewState.nextId = isPushing ? nextId : nil
    return .none
  case .nextParent:
    return self.forEach(
      state: \.parentStates,
      action: /PersonAction.nextParent,
      environment: { $0 }
    )
    .run(&state, action, environment)
  case .nextChild:
    return self.forEach(
      state: \.childrenStates,
      action: /PersonAction.nextChild,
      environment: { $0 }
    )
    .run(&state, action, environment)
  }
}

struct PersonView: View {
  typealias ViewStoreType = ViewStore<PersonState, PersonAction>
  let store: Store<PersonState, PersonAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      VStack(spacing: 8) {
        buildColor(viewStore)
        Divider()
        buildChangeColor(viewStore)
        buildParentLink(viewStore)
        buildChildrenLinks(viewStore)
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
  private func buildParentLink(_ viewStore: ViewStoreType) -> some View {
    HStack {
      ForEachStore(
        store.scope(
          state: \.parentStates,
          action: PersonAction.nextParent
        )
      ) { nextStore in
        WithViewStore(nextStore) { nextViewStore in
          NavigationLink(isActive: Binding(
            get: { viewStore.viewState.nextId == nextViewStore.id },
            set: { isPushing in viewStore.send(.pushToNextPerson(nextViewStore.id, isPushing)) }
          )) {
            PersonView(store: nextStore)
          } label: {
            Text(nextViewStore.person?.name ?? "")
          }
        }
      }
    }
  }

  @ViewBuilder
  private func buildChildrenLinks(_ viewStore: ViewStoreType) -> some View {
    HStack {
      ForEachStore(
        store.scope(
          state: \.childrenStates,
          action: PersonAction.nextChild
        )
      ) { nextStore in
        WithViewStore(nextStore) { nextViewStore in
          NavigationLink(isActive: Binding(
            get: { viewStore.viewState.nextId == nextViewStore.id },
            set: { isPushing in viewStore.send(.pushToNextPerson(nextViewStore.id, isPushing)) }
          )) {
            PersonView(store: nextStore)
          } label: {
            Text(nextViewStore.person?.name ?? "")
          }
        }
      }
    }
  }
}

#if DEBUG
  struct PersonView_Previews: PreviewProvider {
    static let id = UUID()
    static let person = Person(
      name: "Me",
      color: .green,
      parentIds: [],
      childrenIds: []
    )

    static var previews: some View {
      NavigationView {
        PersonView(
          store: .init(
            initialState: .init(
              shared: .init(people: [id: person]),
              viewState: .init(id: id)
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
