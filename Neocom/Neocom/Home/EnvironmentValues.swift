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

struct ESIKey: EnvironmentKey {
    static var defaultValue: ESI {
        ESI()
    }
}

struct SDEKey: EnvironmentKey {
    static var defaultValue: SDE = SDE()
}

struct AccountKey: EnvironmentKey {
    static var defaultValue: Account? = nil
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
    
    var sde: SDE {
        get {
            self[SDEKey.self]
        }
        set {
            self[SDEKey.self] = newValue
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
}
