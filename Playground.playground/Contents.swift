//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

class S {
	var i: Int = 0
}

var d = [Int: S]()

d[1, default: S()].i += 1

print("\(d)")
