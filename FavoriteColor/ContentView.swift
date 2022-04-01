//
//  ContentView.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import ComposableArchitecture
import SwiftUI

struct Person: Equatable {
  let name: String
  var color: Color
  let parentIds: [UUID]
  let childrenIds: [UUID]
}

struct SharedData: Equatable {
  var people: [UUID: Person]
}

struct AppState: Equatable {
  var shared: SharedData = .init(people: Family)
  var myViewState: PersonViewState = .init(id: myUUID)

  var me: PersonState {
    get {
      .init(shared: shared, viewState: myViewState)
    }
    set {
      shared = newValue.shared
      myViewState = newValue.viewState
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

let AppReducer = Reducer<
  AppState,
  AppAction,
  AppEnvironment
>.combine(
  PersonReducer.pullback(
    state: \.me,
    action: /AppAction.person,
    environment: { _ in .live }
  )
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
