//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

extension NSManagedObject {
	var myProp: NSManagedObject? {
		set {
			setPrimitiveValue(newValue, forKey: "myProp")
		}
		get {
			return primitiveValue(forKey: "myProp")
		}
	}
}

class My: NSObject {
	@objc var s: String?
	init(_ s: String) {
		self.s = s
	}
}

let a = [My("1"), My("2"), My("3")]

//(a as NSArray).filtered(using: NSPredicate(format: "%K == %@", [\My.s, "2"]))
let s = #keyPath(My.s)
print(s)
//print(String(describing: \My.s))

