//
//  Math.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

extension Int {
	func clamped(to: ClosedRange<Int>) -> Int {
		return Swift.max(to.lowerBound, Swift.min(to.upperBound, self))
	}
}
