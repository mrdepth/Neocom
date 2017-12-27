//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData


extension Array where Element: Comparable {
	func group(by closure: (Element, Element) -> Bool) -> [ArraySlice<Element>] {
		var copy = self
		var result = [ArraySlice<Element>]()
		let n = count
		var left = 0
		while left < n {
			let first = copy[left]
			let right = copy[left..<n].partition { (i) -> Bool in
				return !closure(first, i)
			}
			print("\(left..<right)")
			result.append(copy[left..<right])
			left = right
		}
		return result
	}
}

var array = [1,1,2,3,4,5,6,8].group(by: {$0 == $1})

print("\(array.map{Array($0)})")

var a = [1,2,3,4,5,6]
let i = a[0..<a.count].partition(by: {$0 % 2 == 0})

print("\(a[0..<i])")
print("\(Array(stride(from: 1, to: 11, by: 1)))")
