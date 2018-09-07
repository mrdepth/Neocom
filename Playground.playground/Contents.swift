//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

typealias AnyID = AnyHashable

let a = [1]
a.reduce(0) { (a,b) -> Int in
	print(a + b)
	return a
}
