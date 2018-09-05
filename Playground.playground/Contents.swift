//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

protocol P: Equatable {
}

class A: P {
	static func == (lhs: A, rhs: A) -> Bool {
		return false
	}
}

class B: A {
	static func == (lhs: B, rhs: B) -> Bool {
		return true
	}
}

func eq<T: P>(_ a: T, _ b: T) -> Bool {
	return a == b
}

eq(A(), A())
eq(B(), B())
