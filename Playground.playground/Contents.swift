//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

protocol P {
}

class A {
	func test() {
		(self as? P)?.hi()
	}
}

class B: A, P {
	override func test() {
		super.test()
	}
	
//	func hi() {
//		print("hi")
//	}
}

let a: A = B()

a.test()

extension P {
	func hi() {
		print("hji")
	}
}