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
    case notificationSettigs = "notificationSettigs"
    case notificationsEnabled = "notificationsEnabled"
    case languageID = "languageID"
    case latestLaunchedVersion = "latestLaunchedVersion"
}


@propertyWrapper class UserDefault<Value: Equatable>: ObservableObject {
    private var _wrappedValue: Value
    var wrappedValue: Value {
        get {
            _wrappedValue
        }
        set {
            objectWillChange.send()
            if let value = newValue as? NSObject {
                _wrappedValue = newValue
                userDefaults.set(value, forKey: key)
                userDefaults.synchronize()
            }
            else {
                _wrappedValue = initialValue
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    var objectWillChange = ObservableObjectPublisher()

    private var userDefaults: UserDefaults
    private var initialValue: Value
    private var key: String
    private var subscription: AnyCancellable?
    
    init(wrappedValue: Value, key: UserDefaultsKey, userDefaults: UserDefaults) {
        let identifier = "\(bundleID).\(key.rawValue)"
        self.key = identifier
        self.userDefaults = userDefaults
        initialValue = wrappedValue
        _wrappedValue = userDefaults.value(forKey: identifier) as? Value ?? wrappedValue

        subscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: userDefaults).sink { [weak self] note in
            guard let strongSelf = self else {return}
            guard let userDefaults = note.object as? UserDefaults else {return}
            let newValue = userDefaults.value(forKey: identifier) as? Value ?? strongSelf.initialValue
            guard strongSelf._wrappedValue != newValue else {return}
            strongSelf.objectWillChange.send()
            strongSelf._wrappedValue = newValue
		}
    }
    
    convenience init(wrappedValue: Value, key: UserDefaultsKey) {
        self.init(wrappedValue: wrappedValue, key: key, userDefaults: .standard)
    }
    
}
