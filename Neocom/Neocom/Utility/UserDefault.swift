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
}


@propertyWrapper class UserDefault<Value>: ObservableObject, DynamicProperty {
    var wrappedValue: Value {
        get {
            return userDefaults.value(forKey: "\(bundleID).\(key.rawValue)") as? Value ?? initialValue
        }
        set {
            userDefaults.set(newValue, forKey: "\(bundleID).\(key.rawValue)")
        }
    }
    
    var objectWillChange = ObjectWillChangePublisher()

    private var userDefaults: UserDefaults
    private var initialValue: Value
    private var key: UserDefaultsKey
    private var subscription: AnyCancellable?
    
    init(wrappedValue: Value, key: UserDefaultsKey, userDefaults: UserDefaults) {
        self.key = key
        self.userDefaults = userDefaults
        initialValue = wrappedValue
        let willChange = objectWillChange
        subscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: userDefaults).sink { [weak self] _ in willChange.send()
			self?.update()
		}
    }

    convenience init(wrappedValue: Value, key: UserDefaultsKey) {
        self.init(wrappedValue: wrappedValue, key: key, userDefaults: .standard)
    }

}
