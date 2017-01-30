//: Playground - noun: a place where people can play

import UIKit

class C1: NSObject {
	let int: Int
	init(_ int: Int) {
		self.int = int
		super.init()
	}
	
	public static func ==(lhs: C1, rhs: C1) -> Bool {
		return lhs.int == rhs.int
	}
	
	override var hash: Int {
		return int
	}
	
	override var hashValue: Int {
		return hash
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? C1) == self
	}
}

var array = [C1(1), C1(2), C1(3)]
array.index(of: C1(2))

//array.index(of: C1(2))