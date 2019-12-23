//
//  Lazy.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/29/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine

class Lazy<Value: ObservableObject>: ObservableObject {
	private var wrappedValue: Value? {
		didSet {
            let subject = objectWillChange
            subscription = wrappedValue?.objectWillChange.sink { _ in
                subject.send()
            }
		}
	}
    private var subscription: AnyCancellable?
    
    var objectWillChange: ObservableObjectPublisher = ObservableObjectPublisher()
    
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
