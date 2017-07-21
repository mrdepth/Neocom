//: Playground - noun: a place where people can play

import UIKit

class InvType<T> {
	
	let object: T
	
	required init(_ object: T) {
		self.object = object
	}
	
	func prototype() -> String? {
		return nil
	}
}

extension InvType where T == NSDictionary {
	
	func prototype() -> String? {
		return "NSDictionary"
	}
}

class A<T> {
	typealias TT = T
	let v: InvType<T>
	required init(obj: T) {
		let v = InvType<TT>(obj)
		print("\(v.prototype())")
		print("\(v)")
		self.v = v
	}
}

let t = A<NSDictionary>.self

let a = t.init(obj: NSDictionary())

let v = InvType<NSDictionary>(NSDictionary())
print("\(v.prototype())")

print("\(a.v)")
print("\(v)")
a.v.prototype() ?? ""
v.prototype() ?? ""