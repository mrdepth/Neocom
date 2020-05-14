//
//  Lazy.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/29/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine

class Lazy<Value, Tag: Equatable>: ObservableObject {
	private var wrappedValue: Value?
    private var subscription: AnyCancellable?
    private var tag: Tag?
    
    var objectWillChange: ObservableObjectPublisher = ObservableObjectPublisher()
}

extension Lazy {
    func get(_ tag: Tag, initial initialValue: @autoclosure () -> Value) -> Value {
        if let value = wrappedValue, tag == self.tag {
            return value
        }
        else {
            self.tag = tag
            wrappedValue = initialValue()
            return wrappedValue!
        }
    }
}

extension Lazy where Tag == Never {
    func get(initial initialValue: @autoclosure () -> Value) -> Value {
        if let value = wrappedValue {
            return value
        }
        else {
            wrappedValue = initialValue()
            return wrappedValue!
        }
    }
}

extension Lazy where Value: ObservableObject {

    private func observeChanges(of object: Value?) {
        let subject = objectWillChange
        subscription = object?.objectWillChange.sink { _ in
            subject.send()
        }
    }

    func get(_ tag: Tag, initial initialValue: @autoclosure () -> Value) -> Value {
        if let value = wrappedValue, tag == self.tag {
            return value
        }
        else {
            self.tag = tag
            wrappedValue = initialValue()
            observeChanges(of: wrappedValue)
            return wrappedValue!
        }
    }
}

extension Lazy where Value: ObservableObject, Tag == Never {
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

}
