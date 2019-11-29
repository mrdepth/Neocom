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
    private var store: Value?
    private var subscription: AnyCancellable?
    
    var objectWillChange: ObservableObjectPublisher = ObservableObjectPublisher()
    
    func get(initial initialValue: @autoclosure () -> Value) -> Value {
        if let value = store {
            return value
        }
        else {
            store = initialValue()
            let subject = objectWillChange
            subscription = store!.objectWillChange.sink { _ in
                subject.send()
            }
            return store!
        }
    }
}
