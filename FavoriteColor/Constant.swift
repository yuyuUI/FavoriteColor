//
//  Constant.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import IdentifiedCollections
import SwiftUI

let parentUUID = UUID()
let myUUID = UUID()
let sonUUID = UUID()
let daughterUUID = UUID()

var parent = Person(
  id: parentUUID,
  name: "Parent",
  color: .green,
  parentId: nil,
  childrenIds: [myUUID]
)

var me = Person(
  id: myUUID,
  name: "Me",
  color: .green,
  parentId: parentUUID,
  childrenIds: [sonUUID, daughterUUID]
)

var son = Person(
  id: sonUUID,
  name: "Son",
  color: .green,
  parentId: myUUID,
  childrenIds: []
)

var daughter = Person(
  id: daughterUUID,
  name: "Daughter",
  color: .green,
  parentId: myUUID,
  childrenIds: []
)

var Family: IdentifiedArrayOf<Person> = [
  parent,
  me,
  son,
  daughter
]
