//
//  Cache.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/29/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation

class Cache<Key: Hashable, Value> {
    private var store: [Key: Value] = [:]
    
    subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        if let value = store[key] {
            return value
        }
        else {
            let value = defaultValue()
            store[key] = value
            return value
        }
    }
}
