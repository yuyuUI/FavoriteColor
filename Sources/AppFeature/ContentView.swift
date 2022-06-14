//
//  ContentView.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import ComposableArchitecture
import SwiftUI
import Tagged

struct Person: Equatable, Identifiable {
  typealias Id = Tagged<Person, UUID>

  let id: Id
  let name: String
  var color: Color
  let parentId: Id?
  let childrenIds: [Id]
}

struct AppState: Equatable {
  var people = Family
  var myPersonState: PersonState = .init(personId: myId)

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
#if os(iOS)
  public struct ContentView: View {
    typealias ViewStoreType = ViewStore<AppState, AppAction>
    let store: Store<AppState, AppAction>

    public var body: some View {
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

  public extension ContentView {
    init() {
      store = .init(
        initialState: .init(),
        reducer: AppReducer,
        environment: .live
      )
    }
  }

#elseif os(macOS)
  struct MacOSContentView: View {
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
      }
    }
  }
#endif

// #if DEBUG
//  struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//      ContentView(store: .init(
//        initialState: .init(),
//        reducer: AppReducer,
//        environment: .live
//      ))
//    }
//  }
// #endif
