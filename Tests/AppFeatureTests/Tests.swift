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
    func test() throws {
        let testStore = TestStore(initialState: AppState(), reducer: AppReducer, environment: AppEnvironment())
        var action = PersonAction.changeColor(.blue)
        testStore.send(.person(action)) {
            $0.people[id: myId]!.color = .blue
        }
        var receive = loadNext(&action, id: sonId)
        testStore.send(.person(action))
        testStore.receive(.person(receive))
        XCTAssertEqual(action, .loadNextPerson(sonId))

        changeColor(&action, .gray)
        testStore.send(.person(action)) {
            $0.people[id: sonId]?.color = .gray
        }
        testStore.send(.person(.nextPerson(.setPushingNextPerson(false))))
    }
}

func changeColor(_ action: inout PersonAction, _ color: Color) {
    switch action {
    case .loadNextPerson:
        action = .nextPerson(.changeColor(color))
    case var .nextPerson(personAction):
        changeColor(&personAction, color)
        action = personAction
    default:
        action = .changeColor(color)
    }
}

func loadNext(_ action: inout PersonAction, id: Person.Id) -> PersonAction {
    action = .loadNextPerson(id)
    return .setPushingNextPerson(true)
}
