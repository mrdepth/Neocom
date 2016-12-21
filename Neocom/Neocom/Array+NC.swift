//
//  Array+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

extension Array where Element: Hashable {
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
