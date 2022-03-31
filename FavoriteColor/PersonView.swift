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
  var person: Person
  var parentStates: IdentifiedArrayOf<PersonState> = []
  var childrenStates: IdentifiedArrayOf<PersonState> = []
}

indirect enum PersonAction: Equatable {
  case changeColor(UUID, Color)
  case updateParentsAndChildren(SharedData)
  case updateSharedData(SharedData)
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
  case .changeColor:
    return .none
  case let .updateParentsAndChildren(sharedData):
    if let parentId = state.person.parentId,
       let parent = sharedData.people[parentId] {
      state.parentStates = IdentifiedArray(uniqueElements: [.init(id: parentId, person: parent)])
    }
    state.childrenStates = IdentifiedArray(
      uniqueElements: state.person.childrenIds.compactMap { childId -> PersonState? in
        guard let child = sharedData.people[childId] else { return nil }
        return .init(id: childId, person: child)
      }
    )
    return .none
  case let .updateSharedData(sharedData):
    if let newPerson = sharedData.people[state.id] {
      state.person = newPerson
    }
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
  @Binding var sharedData: SharedData

  var body: some View {
    WithViewStore(store) { viewStore in
      VStack(spacing: 8) {
        buildColor(viewStore)
        Divider()
        buildChangeColor(viewStore)
        buildParentLinks(viewStore)
        buildChildrenLinks(viewStore)
      }
      .navigationTitle(viewStore.person.name)
      .onChange(of: sharedData) { sharedData in
        viewStore.send(.updateSharedData(sharedData))
      }
      .onAppear {
        viewStore.send(.updateParentsAndChildren(sharedData))
      }
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
          viewStore.send(.changeColor(viewStore.id, color))
        } label: {
          color
            .frame(width: 16, height: 16)
            .cornerRadius(4)
        }
      }
    }
  }

  @ViewBuilder
  private func buildParentLinks(_ viewStore: ViewStoreType) -> some View {
    HStack {
      ForEachStore(
        store.scope(
          state: \.parentStates,
          action: PersonAction.nextParent
        )
      ) { nextStore in
        NavigationLink {
          PersonView(store: nextStore, sharedData: $sharedData)
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
          PersonView(store: nextStore, sharedData: $sharedData)
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
    static let person = Person(
      name: "Me",
      color: .green,
      parentId: nil,
      childrenIds: []
    )

    static var previews: some View {
      NavigationView {
        PersonView(
          store: .init(
            initialState: .init(id: UUID(), person: person),
            reducer: PersonReducer,
            environment: .live
          ),
          sharedData: .constant(.init(people: [id: person]))
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
