//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

class A: NSObject {
	let value: Int
	init(_ value: Int) {
		self.value = value
		super.init()
	}
	
	override var hashValue: Int {
		print("\(value)")
		return value
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		print("==")
		return (object as? A)?.hashValue == hashValue
	}
	
}


let a = [0,1,2,3,4,5,6,7,8,9,4].map{A($0)}

print("set")
var s = Set(a)
print("find")

s.remove(A(4))