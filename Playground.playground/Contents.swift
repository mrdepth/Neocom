//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

class A: NSObject {
	@objc var i: NSNumber = 0
}

let a = A()

var obs: NSKeyValueObservation? = a.observe(\A.i) { (a, change) in
	print(change)
}

a.i = 1

obs = nil
a.i = 2

print("end")
