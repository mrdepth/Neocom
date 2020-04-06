//
//  Lazy.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/29/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine

class Lazy<Value>: ObservableObject {
	private var wrappedValue: Value?
    private var subscription: AnyCancellable?
    
    var objectWillChange: ObservableObjectPublisher = ObservableObjectPublisher()
    
}

extension Lazy {
    func get(initial initialValue: @autoclosure () -> Value) -> Value {
        if let value = wrappedValue {
            return value
        }
        else {
            wrappedValue = initialValue()
            return wrappedValue!
        }
    }
    
    func set(_ value: Value) {
        wrappedValue = value
        objectWillChange.send()
    }
}

extension Lazy where Value: ObservableObject {
    func get(initial initialValue: @autoclosure () -> Value) -> Value {
        if let value = wrappedValue {
            return value
        }
        else {
            wrappedValue = initialValue()
            observeChanges(of: wrappedValue)
            return wrappedValue!
        }
    }
    
    func set(_ value: Value) {
        wrappedValue = value
        observeChanges(of: wrappedValue)
        objectWillChange.send()
    }

    
    private func observeChanges(of object: Value?) {
        let subject = objectWillChange
        subscription = object?.objectWillChange.sink { _ in
            subject.send()
        }
    }
}
