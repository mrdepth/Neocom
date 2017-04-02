//: Playground - noun: a place where people can play

import UIKit
import CoreData

extension Array where Element: Equatable {
	func transition(to: Array<Element>, handler: (_ oldIndex: Int?, _ newIndex: Int?, _ changeType: NSFetchedResultsChangeType) -> Void) {
		let from = self
		var arr = from
		
		for i in (0..<from.count).reversed() {
			if to.index(of: from[i]) == nil {
				handler(i, nil, .delete)
				arr.remove(at: i)
			}
		}
		for i in 0..<to.count {
			let obj = to[i]
			if let j = arr.index(of: obj) {
				if j != i {
					handler(from.index(of: obj), i, .move)
				}
				else {
					handler(from.index(of: obj), i, .update)
				}
			}
			else {
				handler(nil, i, .insert)
			}
		}
	}
	
	mutating func remove(at: IndexSet) {
		for i in at.reversed() {
			self.remove(at: i)
		}
	}
}

var from = [1,2,3,4,5]
var to = [1,2,4,3,5]

from.transition(to: to) { (old, new, type) in
	print("\(old) \(new) \(type.rawValue)")
}