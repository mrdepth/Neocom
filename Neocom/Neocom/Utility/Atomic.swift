//
//  Atomic.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/6/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation

@propertyWrapper class Atomic<Value> {
    private var store: Value
    private var lock = NSLock()
    
    init(_ initialValue: Value) {
        self.store = initialValue
    }
    var wrappedValue: Value {
        get {
            lock.lock()
            defer {lock.unlock()}
            return store
        }
        set {
            lock.lock()
            defer {lock.unlock()}
            store = newValue
        }
    }
    
    func transform(_ execute: (inout Value) throws -> Void) rethrows {
        lock.lock()
        defer {lock.unlock()}
        try execute(&store)
    }
}
