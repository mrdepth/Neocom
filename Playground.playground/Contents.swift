//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

extension RandomAccessCollection {
	
	public func lowerBound(where predicate: (Element) throws -> Bool) rethrows -> Self.SubSequence {
		guard !indices.isEmpty else {return self[endIndex...]}
		var lower = indices.first!
		var count = indices.count
		
		while count > 0 {
			let step = count / 2
			let j = index(lower, offsetBy: step)
			
			if try predicate(self[j]) {
				lower = index(after: j)
				count -= step + 1
			}
			else {
				count = step
			}
		}
		
		return self[..<lower]
	}
	
	public func upperBound(where predicate: (Element) throws -> Bool) rethrows -> Self.SubSequence {
		guard !indices.isEmpty else {return self[endIndex...]}
		var lower = indices.first!
		var count = indices.count
		
		while count > 0 {
			let step = count / 2
			let j = index(lower, offsetBy: step)
			
			if try !predicate(self[j]) {
				lower = index(after: j)
				count -= step + 1
			}
			else {
				count = step
			}
		}
		
		return self[lower...]
	}
	
	public func equalRange(lowerBound: (Element) throws -> Bool, upperBound: (Element) throws -> Bool) rethrows -> Self.SubSequence {
		let lower = try self.lowerBound(where: lowerBound)
		let upper = try self[lower.endIndex...].upperBound(where: upperBound)
		return self[lower.endIndex..<upper.startIndex]
	}
	
}

let a = [5,4,2,1]

print(Array(a.upperBound(where: {$0 <= 3})))
