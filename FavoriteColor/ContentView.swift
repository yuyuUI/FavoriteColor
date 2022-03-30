//
//  ContentView.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import ComposableArchitecture
import SwiftUI

struct SharedData: Equatable, Identifiable {
  var id: UUID
  var people: [UUID: Person]
}

struct AppState: Equatable {
  var shared: SharedData = .init(id: UUID(), people: Family)

  var me: PersonState {
    get {
      .init(id: myUUID, shared: shared)
    }
    set {
      guard shared.id != newValue.shared.id else { return }
      shared = newValue.shared
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
