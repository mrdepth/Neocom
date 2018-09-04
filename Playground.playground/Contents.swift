//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

protocol P {
	var a: Int? {get}
	var b: Int? {get}
}

extension P {
//	var b: Int? {
//		return nil
//	}
}

class A: P {
	var a: Int? {
		return 0
	}
	var b: Int? {
		return 1
	}

}

let a = A()
print(a.a ?? -1)
print(a.b ?? -1)
