//
//  File.swift
//  
//
//  Created by Yu Yu on 2022/6/14.
//

import Foundation
import IdentifiedCollections

@dynamicMemberLookup
struct BaseState<State>: Equatable where State: Equatable {
  var people: IdentifiedArrayOf<Person>
  var state: State

  subscript<Value>(dynamicMember keyPath: WritableKeyPath<State, Value>) -> Value {
    get { self.state[keyPath: keyPath] }
    set { self.state[keyPath: keyPath] = newValue }
  }
}

extension BaseState: Identifiable where State: Identifiable {
  var id: State.ID { state.id }
}

extension BaseState where State == PersonState {
    var person: Person? {
        get {
            people[id: state.personId]
        }
        set {
            people[id: state.personId] = newValue
        }
    }

    var nextPersonFeatureState: BaseState<PersonState>? {
        get {
            switch state.nextPersonState {
            case .none:
                return nil
            case let .some(nextState):
                return .init(people: people, state: nextState)
            }
        }
        set {
            guard let nextPersonFeatureState = newValue else { return }
            people = nextPersonFeatureState.people
            state.nextPersonState = .some(nextPersonFeatureState.state)
        }
    }
}
