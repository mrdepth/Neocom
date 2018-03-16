//
//  Atomic.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.03.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

struct Atomic<Value> {
	private var value: Value
	private var lock = NSLock()
	
	init(_ value: Value) {
		self.value = value
	}
	
	mutating func perform<T>(_ execute:(inout Value) throws -> T ) rethrows -> T{
		return try lock.perform {
			return try execute(&value)
		}
	}
}
