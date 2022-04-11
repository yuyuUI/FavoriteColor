//
//  Constant.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import SwiftUI

let parentUUID = UUID()
let myUUID = UUID()
let sonUUID = UUID()
let daughterUUID = UUID()

var parent = Person(
  name: "Parent",
  color: .green,
  parentId: nil,
  childrenIds: [myUUID]
)

var me = Person(
  name: "Me",
  color: .green,
  parentId: parentUUID,
  childrenIds: [sonUUID, daughterUUID]
)

var son = Person(
  name: "Son",
  color: .green,
  parentId: myUUID,
  childrenIds: []
)

var daughter = Person(
  name: "Daughter",
  color: .green,
  parentId: myUUID,
  childrenIds: []
)

var Family: [UUID: Person] = [
  parentUUID: parent,
  myUUID: me,
  sonUUID: son,
  daughterUUID: daughter
]
