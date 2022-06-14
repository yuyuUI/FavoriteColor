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
        var deep = 0
        var action = level(action: .changeColor(.blue), level: deep)
        testStore.send(.person(action)) {
            $0.people[id: myId]!.color = .blue
        }
        let receive = loadNext(&action, id: sonId)
        testStore.send(.person(action))
        testStore.receive(.person(receive))
        XCTAssertEqual(action, .loadNextPerson(sonId))

        changeColor(&action, .gray)
        testStore.send(.person(action)) {
            $0.people[id: sonId]?.color = .gray
        }

        
    }

    func testLoadNext() {
        var action = PersonAction.nextPerson(.setPushingNextPerson(true))
        let id = Person.Id(rawValue: UUID())
        _ = loadNext(&action, id: id)
        XCTAssertEqual(action, .nextPerson(.loadNextPerson(id)))
    }
}

func changeColor(_ action: inout PersonAction, _ color: Color) {
    switch action {
    case .loadNextPerson:
        action = .nextPerson(.changeColor(color))
    case var .nextPerson(personAction):
        changeColor(&personAction, color)
        action = .nextPerson(personAction)
    default:
        action = .changeColor(color)
    }
}

func loadNext(_ action: inout PersonAction, id: Person.Id) -> PersonAction {
    switch action {
    case .nextPerson(var personAction):
        _ = loadNext(&personAction, id: id)
        action = .nextPerson(personAction)
    default:
        action = .loadNextPerson(id)
    }
    return .setPushingNextPerson(true)
}

func level(action: PersonAction, level: Int) -> PersonAction {
    var action = action
    for _ in 0..<level {
        action = .nextPerson(action)
    }
    return action
}
