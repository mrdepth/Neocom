//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

class A: NSObject {
	deinit {
		print("~A")
	}
}

var m: NSMapTable<NSString, A>? = NSMapTable.strongToWeakObjects()
autoreleasepool {
	do {
		let a = A()
		m?.setObject(a, forKey: "12")
		//	a = nil
		print("\(m!.object(forKey: "12"))")
	}
}
print("\(m!.object(forKey: "12"))")
print("exit")
