//
//  ContentView.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import ComposableArchitecture
import SwiftUI

struct Person: Equatable, Identifiable {
  let id: UUID
  let name: String
  var color: Color
  let parentId: UUID?
  let childrenIds: [UUID]
}

@dynamicMemberLookup
struct BaseState<State>: Equatable where State: Equatable {
  var people: IdentifiedArrayOf<Person>
  var state: State

  subscript<Value>(dynamicMember keyPath: WritableKeyPath<State, Value>) -> Value {
    get { self.state[keyPath: keyPath] }
    set { self.state[keyPath: keyPath] = newValue }
  }
}

extension BaseState: Identifiable where State: Identifiable {
  var id: State.ID { state.id }
}

struct AppState: Equatable {
  var people = Family
  var myPersonState: PersonState = .init(personId: myUUID)

  var me: BaseState<PersonState> {
    get {
      .init(
        people: people,
        state: myPersonState
      )
    }
    set {
      people = newValue.people
      myPersonState = newValue.state
    }
  }
}

enum AppAction: Equatable {
  case person(PersonAction)
}

struct AppEnvironment {}

extension AppEnvironment {
  static var live = Self()
}

let AppReducer: Reducer<
  AppState,
  AppAction,
  AppEnvironment
> = PersonReducer.pullback(
  state: \.me,
  action: /AppAction.person,
  environment: { _ in .live }
)
.debug()

struct ContentView: View {
  typealias ViewStoreType = ViewStore<AppState, AppAction>
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationView {
        PersonView(
          store: store.scope(
            state: \.me,
            action: AppAction.person
          )
        )
      }
      .navigationViewStyle(.stack)
    }
  }
}

#if DEBUG
  struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      ContentView(store: .init(
        initialState: .init(),
        reducer: AppReducer,
        environment: .live
      ))
    }
  }
#endif
