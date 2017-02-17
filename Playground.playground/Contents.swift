//: Playground - noun: a place where people can play

import UIKit

enum E {
	case a
	case b
}

let i: Int? = 1
let e = E.a

switch (e, i) {
case (.a, let j?):
	print("a \(j)")
default:
	break
}