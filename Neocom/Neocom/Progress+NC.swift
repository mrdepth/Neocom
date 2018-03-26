//
//  Progress+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

extension Progress {
	
	@discardableResult
	func perform<T>(pendingUnitCount: Int64 = 1, block: () throws -> T) rethrows -> T {
		let left = min(pendingUnitCount, totalUnitCount - completedUnitCount)
		if left > 0 {
			if Progress.current() == self {
				resignCurrent()
				becomeCurrent(withPendingUnitCount: left)
				return try block()
			}
			else {
				becomeCurrent(withPendingUnitCount: left)
				defer {resignCurrent()}
				return try block()
			}
		}
		else {
			return try block()
		}
	}
}
