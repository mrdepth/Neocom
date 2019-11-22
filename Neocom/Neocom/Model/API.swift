//
//  API.swift
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

//class API: ObservableObject, ESIDelegate {
//    func tokenDidRefresh(_ token: OAuth2Token) {
//        objectWillChange.send()
//    }
//
//    func tokenDidBecomeInvalid(_ token: OAuth2Token) {
//        objectWillChange.send()
//    }
//
//    var esi: ESI
//
//    init(esi: ESI) {
//        self.esi = esi
//        self.esi.delegate = self
//    }
//}

//class ESIAPI {
//
//}
//

class API<Success, Failure: Error>: ObservableObject {

    private var subscription: AnyCancellable?

    func update<P>(_ publisher: P) where P: Publisher, P.Output == Success, P.Failure == Failure {
        subscription = publisher.asResult().sink { [weak self] result in
            self?.result = result
        }
    }
    
    @Published var result: Result<Success, Failure>?
    
    func publisher() -> Published<Result<Success,Failure>?>.Publisher {
        return $result
    }

}
