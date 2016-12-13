//: Playground - noun: a place where people can play

import UIKit

extension Double {
	func clamped(to: ClosedRange<Double>) -> Double {
		return max(to.lowerBound, min(to.upperBound, self))
	}
}


var str = "Hello, playground"

var set = NSOrderedSet(array: [1,2,3,4,5])

let s = set.set as? Set<Int>

func f<T:NSCoding> (_ a: T) {
	
}

let array = [1,2,3,4,5]
//f(array as? NSCoding)

let cod = array as NSSecureCoding
let a = Array<Int>()

let d = 1E300

do {
	let i = UInt(d.clamped(to: Double(UInt.min)...Double(Int.max)))
	//d.clamped(to: Double(UInt.min)...Double(UInt.max))
}
catch {
	error
}


