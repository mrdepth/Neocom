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

    func update<P>(_ publisher: P) where P: Publisher, P.Output == Success, P.Failure == Failure {
        subscription = publisher.asResult().sink { [weak self] result in
            self?.result = result
        }
    }
    
    @Published var result: Result<Success, Failure>?
    
    func publisher() -> Publishers.MapError<Publishers.TryMap<Publishers.CompactMap<Published<Result<Success, Failure>?>.Publisher, Result<Success, Failure>>, Success>, Failure> {
		return $result.compactMap{$0}.tryGet()
    }

}
