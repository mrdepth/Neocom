//: Playground - noun: a place where people can play

import UIKit

protocol TableViewCellPrototype {
	static var reuseIdentifier: String {get}
}

class A: TableViewCellPrototype {
	static let reuseIdentifier = "sdf"
}

class B<T: TableViewCellPrototype> {
	func p() {
		print("\(T.reuseIdentifier)")
	}
}

let a: TableViewCellPrototype = A()

type(of: a).reuseIdentifier

B<A>().p()