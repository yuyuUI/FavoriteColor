//
//  ContentView.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import ComposableArchitecture
import SwiftUI

struct SharedData: Equatable {
  var people: [UUID: Person]
}

struct AppState: Equatable {
  var family = Family

  var sharedData: SharedData {
    .init(people: family)
  }

  var me: PersonState? = {
    guard let me = Family[myUUID] else { return nil }
    return .init(id: myUUID, person: me)
  }()
}

enum AppAction: Equatable {
  case person(PersonAction)
}

struct AppEnvironment {}

extension AppEnvironment {
  static var live = Self()
}

let AppReducer = Reducer<
  AppState,
  AppAction,
  AppEnvironment
>.combine(
  PersonReducer.optional().pullback(
    state: \.me,
    action: /AppAction.person,
    environment: { _ in .live }
  ),
  updatePersonReducer
)
.debug()

let updatePersonReducer = Reducer<
  AppState,
  AppAction,
  AppEnvironment
> { state, action, environment in
  switch action {
  case let .person(personAction):
    var personAction = personAction
    var isStop = false

    while !isStop {
      switch personAction {
      case let .changeColor(id, color):
        state.family[id]?.color = color
        isStop = true
      case let .nextParent(_, parentAction):
        personAction = parentAction
      case let .nextChild(_, childAction):
        personAction = childAction
      case .updateParentsAndChildren,
           .updateSharedData:
        isStop = true
      }
    }

    return .none
  }
}

struct ContentView: View {
  typealias ViewStoreType = ViewStore<AppState, AppAction>
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationView {
        IfLetStore(store.scope(
          state: \.me,
          action: AppAction.person
        )) { store in
          PersonView(
            store: store,
            sharedData: Binding(
              get: { viewStore.sharedData },
              set: { _ in }
            )
          )
        }
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
