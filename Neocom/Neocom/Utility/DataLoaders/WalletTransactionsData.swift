//
//  WalletTransactionsData.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Combine
import Alamofire
import CoreData

class WalletTransactionsData: ObservableObject {
    @Published var isLoading = false
    @Published var result: Result<(transactions: ESI.WalletTransactions, contacts: [Int64: Contact], locations: [Int64: EVELocation]), AFError>?
    
    private var esi: ESI
    private var characterID: Int64
    private var managedObjectContext: NSManagedObjectContext
    private var subscription: AnyCancellable?

    init(esi: ESI, characterID: Int64, managedObjectContext: NSManagedObjectContext) {
        self.esi = esi
        self.characterID = characterID
        self.managedObjectContext = managedObjectContext
        update(cachePolicy: .useProtocolCachePolicy)
    }
    
    func update(cachePolicy: URLRequest.CachePolicy) {
        isLoading = true
        let managedObjectContext = self.managedObjectContext
        let esi = self.esi
        let characterID = self.characterID

        subscription = esi.characters.characterID(Int(characterID)).wallet().transactions().get(fromID: nil, cachePolicy: cachePolicy).flatMap { transactions -> AnyPublisher<(ESI.WalletTransactions, [Int64: Contact], [Int64: EVELocation]), AFError> in
            let clientIDs = transactions.value.map{Int64($0.clientID)}
            let locationIDs = transactions.value.map{$0.locationID}
            let contacts = Contact.contacts(with: Set(clientIDs), esi: esi, characterID: characterID, options: [.universe], managedObjectContext: managedObjectContext).replaceError(with: [:])
            let locations = EVELocation.locations(with: Set(locationIDs), esi: esi, managedObjectContext: managedObjectContext).replaceError(with: [:])
            return Publishers.Zip3(Just(transactions.value), contacts, locations).setFailureType(to: AFError.self).eraseToAnyPublisher()
        }.asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.result = result.map{(transactions: $0.0, contacts: $0.1, locations: $0.2)}
                self?.isLoading = false
        }
    }
}
