//
//  Atomic.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.03.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

struct Atomic<Value> {
	private var _value: Value
	private var lock = NSLock()
	
	init(_ value: Value) {
		_value = value
	}
	
	var value: Value {
		get {
			return lock.performCritical { _value }
		}
		set {
			lock.performCritical { _value = newValue }
		}
	}

	
	mutating func perform<T>(_ execute:(inout Value) throws -> T ) rethrows -> T{
		return try lock.performCritical {
			return try execute(&_value)
		}
	}
}
