//
//  UserActivityProvider.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

protocol UserActivityProvider: Equatable {
    func userActivity() -> NSUserActivity?
}

fileprivate protocol AnyUserActivityProviderBox {
    func userActivity() -> NSUserActivity?
    func isEqual(_ other: AnyUserActivityProviderBox) -> Bool
    func unbox<T: UserActivityProvider>() -> T?
}

fileprivate struct ConcreteAnyUserActivityProviderBox<Base: UserActivityProvider>: AnyUserActivityProviderBox {
    var base: Base
    
    func userActivity() -> NSUserActivity? {
        base.userActivity()
    }
    
    func isEqual(_ other: AnyUserActivityProviderBox) -> Bool {
        other.unbox() == base
    }
    
    func unbox<T>() -> T? where T : UserActivityProvider {
        base as? T
    }
}

struct AnyUserActivityProvider: UserActivityProvider {
    
    func userActivity() -> NSUserActivity? {
        box.userActivity()
    }
    
    static func == (lhs: AnyUserActivityProvider, rhs: AnyUserActivityProvider) -> Bool {
        lhs.box.isEqual(rhs.box)
    }
    
    private var box: AnyUserActivityProviderBox
    init<T: UserActivityProvider>(_ base: T) {
        box = ConcreteAnyUserActivityProviderBox(base: base)
    }
}
