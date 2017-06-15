//: Playground - noun: a place where people can play

import UIKit

typealias TreeNode = Int

public enum ChangeType {
	case insert
	case delete
	case move
	case update
}

extension Array where Element == TreeNode {
	
	func changes(from: Array<Element>, handler: (_ oldIndex: Index?, _ newIndex: Index?, _ changeType: ChangeType) -> Void) {
		let to = self
		var arr = from
		
		var removed = IndexSet()
		var inserted = IndexSet()
		var updated = [(Int, Int)]()
		var moved = [(Int, Int)]()
		
		for (i, v) in from.enumerated().reversed() {
			if let j = to.index(of: v) {
				if i == j {
					updated.append((i, j))
				}
				else {
					moved.append((i, j))
				}
				arr.remove(at: i)
			}
			else {
				removed.insert(i)
			}
		}
		
		for (i, v) in to.enumerated() {
			if !from.contains(v) {
				inserted.insert(i)
			}
		}
		
		print("\(removed.map{$0})")
		print("\(inserted.map{$0})")
		print("\(moved.map{$0})")
		print("\(updated.map{$0})")

		if !removed.isEmpty {
			removed.reversed().forEach {handler($0, nil, .delete)}
		}
		if !inserted.isEmpty {
			inserted.forEach {handler(nil, $0, .insert)}
		}
		if !moved.isEmpty {
			moved.reversed().forEach {handler($0.0, $0.1, .move)}
		}
		if !updated.isEmpty {
			updated.forEach {handler($0.0, $0.1, .update)}
		}
		
		/*let to = self
		var arr = from
		
		for (i, v) in from.enumerated().reversed() {
		if to.index(of: v) == nil {
		handler(i, nil, .delete)
		arr.remove(at: i)
		}
		}
		
		var moves = Set<Int>()
		
		for i in indices {
		guard !moves.contains(i) else {continue}
		let obj = to[i]
		if let j = arr[i..<arr.count].index(of: obj) {
		let k = from.index(of: obj)!
		
		if j != i {
		handler(k, i, .move)
		moves.insert(k)
		}
		let obj2 = from[k]
		if obj !== obj2 {
		handler(k, i, .update)
		}
		
		}
		else {
		handler(nil, i, .insert)
		arr.insert(obj, at: i)
		}
		}*/
	}
	
	mutating func remove(at: IndexSet) {
		var copy = self
		for i in at.reversed() {
			copy.remove(at: i)
		}
		self = copy
	}
}

let from = [0,1,3,2]
let to = [2,4,1,0]

var a = from

to.changes(from: from) { (old, new, type) in
	print ("\(type): \(old) \(new)")
	
}
