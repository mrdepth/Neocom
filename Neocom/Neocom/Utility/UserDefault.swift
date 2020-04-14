//
//  UserDefault.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/11/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

enum UserDefaultsKey: String {
    case marketRegionID = "marketRegion"
    case activeAccountID = "activeAccountID"
}


@propertyWrapper class UserDefault<Value>: ObservableObject {
    var wrappedValue: Value {
        get {
            return userDefaults.value(forKey: key) as? Value ?? initialValue
        }
        set {
            if let value = newValue as? NSObject {
                userDefaults.set(value, forKey: key)
                userDefaults.synchronize()
            }
            else {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    var objectWillChange = ObjectWillChangePublisher()

    private var userDefaults: UserDefaults
    private var initialValue: Value
    private var key: String
//    private var key: UserDefaultsKey
    private var subscription: AnyCancellable?
    
    init(wrappedValue: Value, key: UserDefaultsKey, userDefaults: UserDefaults) {
//        self.key = key
        self.key = "\(bundleID).\(key.rawValue)"
        self.userDefaults = userDefaults
        initialValue = wrappedValue
        let willChange = objectWillChange
        subscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: userDefaults).sink { _ in
            willChange.send()
		}
    }
    
    convenience init(wrappedValue: Value, key: UserDefaultsKey) {
        self.init(wrappedValue: wrappedValue, key: key, userDefaults: .standard)
    }
    
}
