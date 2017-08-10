//
//  Progress+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

extension Progress {
	func perform(pendingUnitCount: Int64 = 1, block: () -> Void) {
		if Progress.current() == self {
			resignCurrent()
			becomeCurrent(withPendingUnitCount: pendingUnitCount)
			block()
		}
		else {
			becomeCurrent(withPendingUnitCount: pendingUnitCount)
			block()
			resignCurrent()
		}
	}
}
