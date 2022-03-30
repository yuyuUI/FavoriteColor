//
//  PersonView.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import ComposableArchitecture
import SwiftUI

struct Person: Equatable {
  let name: String
  var color: Color
  let parentId: UUID?
  let childrenIds: [UUID]
}

struct PersonState: Equatable, Identifiable {
  let id: UUID
  var shared: SharedData

  var person: Person {
    shared.people[id]!
  }

  var parentState: PersonState? {
    get {
      guard let parentId = person.parentId else { return nil }
      return .init(id: parentId, shared: shared)
    }
    set {
      guard let newValue = newValue, shared.id != newValue.shared.id else { return }
      shared = newValue.shared
    }
  }

  var childrenStates: IdentifiedArrayOf<PersonState> {
    get {
      IdentifiedArray(
        uniqueElements:
        person.childrenIds.compactMap { childId in
          .init(id: childId, shared: shared)
        }
      )
    }
    set {
      guard let newShared = newValue.map(\.shared).filter({ $0.id != shared.id }).first else { return }
      shared = newShared
    }
  }
}

indirect enum PersonAction: Equatable {
  case changeColor(Color)
  case nextParent(PersonAction)
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
    state.shared.people[state.id]?.color = newColor
    state.shared.id = UUID()
    return .none
  case .nextParent:
    return self.optional().pullback(
      state: \.parentState,
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
      .navigationTitle(viewStore.person.name)
    }
  }

  @ViewBuilder
  private func buildColor(_ viewStore: ViewStoreType) -> some View {
    viewStore.person.color
      .frame(width: 100, height: 100)
      .cornerRadius(16)
      .padding()
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
    IfLetStore(store.scope(
      state: \.parentState,
      action: PersonAction.nextParent
    )) { nextStore in
      VStack {
        NavigationLink {
          PersonView(store: nextStore)
        } label: {
          WithViewStore(nextStore) { nextViewStore in
            Text(nextViewStore.person.name)
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
        NavigationLink {
          PersonView(store: nextStore)
        } label: {
          WithViewStore(nextStore) { nextViewStore in
            Text(nextViewStore.person.name)
          }
        }
      }
    }
  }
}

#if DEBUG
  struct PersonView_Previews: PreviewProvider {
    static let id = UUID()

    static var previews: some View {
      NavigationView {
        PersonView(
          store: .init(
            initialState: .init(
              id: UUID(),
              shared: .init(
                id: id,
                people: [
                  id: .init(
                    name: "Me",
                    color: .green,
                    parentId: nil,
                    childrenIds: []
                  ),
                ]
              )
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
