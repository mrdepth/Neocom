//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

protocol P {
//	associatedtype T
//	var i: T {get set}
	func f1()
	func f2()
	func some() -> Self
}

class A: P {
	var i: Int = 1
	func some() -> Self {
		print("some")
		return self
	}
	
	func f1() {
		print("A:f1")
	}
}


extension P {
	func f1() {
		print("P:f1")
	}
	func f2() {
		print("P:f2")
	}
//	func some() -> Self {
//		return self
//	}
}


A().f1()
A().f2()

func f(arg: P) {
	print("\(type(of: arg.some()))")
}


f(arg: A())
