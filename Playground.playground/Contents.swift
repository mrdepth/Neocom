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


func hashCombine(seed: inout Int, value: Int) {
	seed ^= value &+ Int(truncatingBitPattern: Int64(0x9e3779b9)) &+ (seed << 6) &+ (seed >> 2)
}

var seed = Int(0x8000000)

hashCombine(seed: &seed, value: 123)
hashCombine(seed: &seed, value: 321)