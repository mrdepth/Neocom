//
//  EnvironmentValues.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/22/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import SwiftUI
import EVEAPI
import CoreData

struct ESIKey: EnvironmentKey {
    static var defaultValue: ESI {
        ESI()
    }
}

struct AccountKey: EnvironmentKey {
    static var defaultValue: Account? = nil
}

struct BackgroundManagedObjectContextKey: EnvironmentKey {
    static var defaultValue: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
}

struct TypePickerManagerKey: EnvironmentKey {
    static var defaultValue = TypePickerManager()
}

extension EnvironmentValues {
    var esi: ESI {
        get {
            self[ESIKey.self]
        }
        set {
            self[ESIKey.self] = newValue
        }
    }
    
    var account: Account? {
        get {
            self[AccountKey.self]
        }
        set {
            self[AccountKey.self] = newValue
        }
    }
    
    var backgroundManagedObjectContext: NSManagedObjectContext {
        get {
            self[BackgroundManagedObjectContextKey.self]
        }
        set {
            self[BackgroundManagedObjectContextKey.self] = newValue
        }
    }
    var typePicker: TypePickerManager {
        get {
            self[TypePickerManagerKey.self]
        }
        set {
            self[TypePickerManagerKey.self] = newValue
        }
    }
}
