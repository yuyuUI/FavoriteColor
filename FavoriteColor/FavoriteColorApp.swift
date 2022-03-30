//
//  FavoriteColorApp.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import SwiftUI

@main
struct FavoriteColorApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView(store: .init(
        initialState: .init(),
        reducer: AppReducer,
        environment: .live)
      )
    }
  }
}
