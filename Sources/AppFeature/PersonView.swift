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
  let personId: Person.Id
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
  case loadNextPerson(Person.Id)
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
  typealias ViewStoreType = ViewStore<ViewState, PersonAction>
  let store: Store<BaseState<PersonState>, PersonAction>

  struct ViewState: Equatable {
    struct Member: Equatable, Identifiable {
      let id: Person.Id
      let name: String
    }

    let person: Person?
    let parent: Member?
    let children: IdentifiedArrayOf<Member>
    let isPushingNextPerson: Bool
  }

  var body: some View {
    WithViewStore(store.scope(state: ViewState.init)) { viewStore in
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
    if let parent = viewStore.parent {
      HStack {
        Text("Parent:")
        Button(parent.name) {
          viewStore.send(.loadNextPerson(parent.id))
        }
      }
    }
  }

  @ViewBuilder
  private func buildChildrenStack(_ viewStore: ViewStoreType) -> some View {
    if !viewStore.children.isEmpty {
      HStack {
        Text("Children:")

        ForEach(viewStore.children) { child in
          Button(child.name) {
            viewStore.send(.loadNextPerson(child.id))
          }
        }
      }
    }
  }

  @ViewBuilder
  private func buildNavigationLink(_ viewStore: ViewStoreType) -> some View {
    NavigationLink(isActive: viewStore.binding(
      get: \.isPushingNextPerson,
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

private extension PersonView.ViewState {
  init(_ state: BaseState<PersonState>) {
    let parentMember: Member?
    if let parentId = state.person?.parentId,
       let parent = state.people[id: parentId] {
      parentMember = .init(id: parentId, name: parent.name)
    } else {
      parentMember = nil
    }

    let childMembers: IdentifiedArrayOf<Member>
    if let childIds = state.person?.childrenIds {
      childMembers = IdentifiedArray(
        uniqueElements: childIds
          .compactMap { state.people[id: $0] }
          .map { Member(id: $0.id, name: $0.name) }
      )
    } else {
      childMembers = []
    }

    self.init(
      person: state.person,
      parent: parentMember,
      children: childMembers,
      isPushingNextPerson: state.nextPersonState != .none
    )
  }
}

#if DEBUG
  struct PersonView_Previews: PreviewProvider {
    static let person = Person(
      id: myId,
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
              state: .init(personId: myId)
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
