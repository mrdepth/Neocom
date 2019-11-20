//
//  NCExtendedLifeTime.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

class NCExtendedLifeTime<T> {
	var ref: T?
	
	init(_ value: T) {
		ref = value
	}
	
	func finalize() {
		ref = nil
	}
}
