//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

let s = "1234.123123"

class A: Hashable {
	var hashValue: Int {
		return 1
	}
	
	static func==(lhs: A, rhs: A) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}

class B: A {
	var i: Int
	init(i: Int) {
		self.i = i
	}
	
	override lazy var hashValue: Int = i
}


print("\(B(i: 15).hashValue)")
