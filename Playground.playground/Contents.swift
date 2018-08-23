//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

enum A: Int {
	case a
}

let desc = NSPersistentStoreDescription()
desc.setOption(A.a.rawValue as NSNumber, forKey: "a")

let d = desc.options as [String: Any]
let a = d["a"] as? A
print(a)
