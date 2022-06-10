//
//  Constant.swift
//  FavoriteColor
//
//  Created by Art Huang on 2022/3/30.
//

import IdentifiedCollections
import SwiftUI

let parentId = Person.Id(rawValue: .init())
let myId = Person.Id(rawValue: .init())
let sonId = Person.Id(rawValue: .init())
let daughterId = Person.Id(rawValue: .init())

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
