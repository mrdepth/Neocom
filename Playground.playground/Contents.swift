//: Playground - noun: a place where people can play

import UIKit

struct S: OptionSet, Hashable {
	var rawValue: Int
	
	static let attr1 = S(rawValue: 1 << 0)
	static let attr2 = S(rawValue: 1 << 0)
	
	var hashValue: Int {
		return rawValue
	}
}

var m: [S: Int] = [:]

m[[.attr1, .attr2]] = 3

m[[.attr2, .attr1]]