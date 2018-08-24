//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

protocol P {
	func f()
}

class A<T>: P {
	
}

class B: A<String> {
	
}

extension P {
	func f() {
		print("\(type(of: self))")
	}
}

let a: P = A<Int>()
let b: P = B()
a.f()
b.f()


func f<T>(_ t: T) {
	print("\(t)")
}

