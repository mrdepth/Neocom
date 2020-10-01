//
//  CorpWalletJournalData.swift
//  Neocom
//
//  Created by Artem Shimanski on 7/2/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Combine
import Alamofire
import CoreData

class CorpWalletJournalData: ObservableObject {
    @Published var isLoading = false
    @Published var result: Result<[(ESI.Wallet, ESI.WalletJournal)], AFError>?
    
    private var esi: ESI
    private var characterID: Int64
    private var subscription: AnyCancellable?

    init(esi: ESI, characterID: Int64) {
        self.esi = esi
        self.characterID = characterID
        update(cachePolicy: .useProtocolCachePolicy)
    }
    
    func update(cachePolicy: URLRequest.CachePolicy) {
        isLoading = true
        let esi = self.esi
        let characterID = self.characterID

        subscription = esi.characters.characterID(Int(characterID)).get().map{esi.corporations.corporationID($0.value.corporationID)}
        .flatMap { corporation in
            corporation.wallets().get().map{$0.value}
            .flatMap { divisions in
                Publishers.Sequence(sequence: divisions).flatMap { division in
                    corporation.wallets().division(division.division).journal().get().map{$0.value.map{$0 as WalletJournalProtocol}}.map{(division, $0)}
                }.collect()
            }
        }
        .asResult()
        .receive(on: RunLoop.main)
        .sink { [weak self] (result) in
            self?.result = result
        }
//
//
//        subscription = esi.characters.characterID(Int(characterID)).wallet().transactions().get(fromID: nil, cachePolicy: cachePolicy).flatMap { transactions -> AnyPublisher<(ESI.WalletTransactions, [Int64: Contact], [Int64: EVELocation]), AFError> in
//            let clientIDs = transactions.value.map{Int64($0.clientID)}
//            let locationIDs = transactions.value.map{$0.locationID}
//            let contacts = Contact.contacts(with: Set(clientIDs), esi: esi, characterID: characterID, options: [.universe], managedObjectContext: managedObjectContext).replaceError(with: [:])
//            let locations = EVELocation.locations(with: Set(locationIDs), esi: esi, managedObjectContext: managedObjectContext).replaceError(with: [:])
//            return Publishers.Zip3(Just(transactions.value), contacts, locations).setFailureType(to: AFError.self).eraseToAnyPublisher()
//        }.asResult()
//            .receive(on: RunLoop.main)
//            .sink { [weak self] result in
//                self?.result = result.map{(transactions: $0.0, contacts: $0.1, locations: $0.2)}
//                self?.isLoading = false
//        }
    }
}
