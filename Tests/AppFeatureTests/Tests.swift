//
//  File.swift
//
//
//  Created by Yu Yu on 2022/6/10.
//

@testable import AppFeature
import ComposableArchitecture
import Foundation
import SwiftUI
import XCTest
final class Atests: XCTestCase {
    typealias Store = TestStore<
        AppState,
        AppState,
        AppAction,
        AppAction,
        AppEnvironment
    >
    fileprivate func color(id: Person.Id, level: Int, color: Color, _ testStore: Store) {
        testStore.send(.level(.changeColor(color), level)) {
            $0.people[id: id]!.color = color
        }
    }

    fileprivate func push(level: Int, id: Person.Id, _ testStore: Store) {
        testStore.send(.level(.loadNextPerson(id), level))
        testStore.receive(.level(.setPushingNextPerson(true), level))
    }

    func test() throws {
        let store = TestStore(initialState: AppState(), reducer: AppReducer, environment: AppEnvironment())
        color(id: myId, level: 0, color: .blue, store)
        push(level: 0, id: sonId, store)
        color(id: sonId, level: 1, color: .blue, store)
        push(level: 1, id: myId, store)
    }
}


extension AppAction {
    static func level(_ personAction: PersonAction, _ level: Int) -> AppAction {
        var action = personAction
        for _ in 0 ..< level {
            action = .nextPerson(action)
        }
        return .person(action)
    }
}
