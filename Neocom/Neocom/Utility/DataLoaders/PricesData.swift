//
//  PricesData.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import SwiftUI
import Alamofire

class PricesData: ObservableObject {
    @Published var prices: Result<[Int: Double], AFError>?
    
    init(esi: ESI) {
        subscription = esi.markets.prices().get()
            .map {
                Dictionary($0.value.map{($0.typeID, $0.averagePrice)}) { (a, b) in a ?? b}.compactMapValues{$0}
        }
        .receive(on: RunLoop.main)
        .asResult()
        .sink { [weak self] result in
            self?.prices = result
        }
    }
    
    private var subscription: AnyCancellable?
}
