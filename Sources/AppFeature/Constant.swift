//
//  Constant.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import IdentifiedCollections
import SwiftUI

let parentId = Person.Id(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
let myId = Person.Id(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
let sonId = Person.Id(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)
let daughterId = Person.Id(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!)

var parent = Person(
  id: parentId,
  name: "Parent",
  color: .green,
  parentId: nil,
  childrenIds: [myId]
)

var me = Person(
  id: myId,
  name: "Me",
  color: .green,
  parentId: parentId,
  childrenIds: [sonId, daughterId]
)

var son = Person(
  id: sonId,
  name: "Son",
  color: .green,
  parentId: myId,
  childrenIds: []
)

var daughter = Person(
  id: daughterId,
  name: "Daughter",
  color: .green,
  parentId: myId,
  childrenIds: []
)

var Family: IdentifiedArrayOf<Person> = [
  parent,
  me,
  son,
  daughter
]
