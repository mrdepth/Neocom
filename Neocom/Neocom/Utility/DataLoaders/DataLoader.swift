//
//  DataLoader.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/22/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import Alamofire
import SwiftUI
import EVEAPI

class DataLoader<Success, Failure: Error>: ObservableObject {

    private var subscription: AnyCancellable?

    var result: Result<Success, Failure>? {
        willSet {
            objectWillChange.send()
        }
    }
    
    var objectWillChange = ObservableObjectPublisher()
    
    init<P: Publisher>(_ publisher: P) where P.Output == Success, P.Failure == Failure {
        update(publisher)
//        subscription = publisher.asResult().sink { [weak self] result in
//            self?.result = result
//        }
    }
    
    func update<P: Publisher>(_ publisher: P) where P.Output == Success, P.Failure == Failure {
        subscription = publisher.asResult().sink { [weak self] result in
            self?.result = result
        }
    }
}
