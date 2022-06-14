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
        testStore.send(.person(.changeColor(.blue))) {
            $0.people[id: myId]!.color = .blue
        }
        testStore.send(.person(.loadNextPerson(sonId))) {
            $0.myPersonState.nextPersonState = .next(.init(personId: sonId))
        }
        testStore.send(.person(.setPushingNextPerson(true)))
        
        testStore.send(.person(.nextPerson(.changeColor(.gray)))) {
            $0.people[id: sonId]?.color = .gray
        }
        testStore.send(.person(.nextPerson(.setPushingNextPerson(false))))
    }
}
