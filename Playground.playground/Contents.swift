//: Playground - noun: a place where people can play

import UIKit

class C {
	let i: Int
	init(i: Int) {
		self.i = i
	}
	
	lazy var v: String = {
		return "\(self.i)"
	}()
	
	deinit {
		print("deinit \(i)")
	}
}

do {
	var c1 = C(i: 1)
	var c2 = C(i: 2)
	_ = c2.v
}