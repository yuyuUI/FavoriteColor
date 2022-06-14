//
//  File.swift
//
//
//  Created by Yu Yu on 2022/6/10.
//

@testable import AppFeature
import ComposableArchitecture
import Foundation
import XCTest
final class Atests: XCTestCase {
    func test() throws {
        let testStore = TestStore(initialState: AppState(), reducer: AppReducer, environment: AppEnvironment())
        var action = PersonAction.changeColor(.blue)
        testStore.send(.person(action)) {
            $0.people[id: myId]!.color = .blue
        }
        action = .loadNextPerson(sonId)
        testStore.send(.person(action))
        testStore.receive(.person(.setPushingNextPerson(true)))

        testStore.send(.person(.nextPerson(.changeColor(.gray)))) {
            $0.people[id: sonId]?.color = .gray
        }
        testStore.send(.person(.nextPerson(.setPushingNextPerson(false))))
    }
}

func loadNext(_ action: inout PersonAction, id: Person.Id) -> PersonAction {
    switch action {
    case let .changeColor(color):
        break
    case let .loadNextPerson(id):
        break
    case let .setPushingNextPerson(bool):
        break
    case let .nextPerson(personAction):
        break
    }
    return action
}
