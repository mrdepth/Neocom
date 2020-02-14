//
//  ContractInfoData.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Combine
import Alamofire
import CoreData

class ContractInfoData: ObservableObject {
    @Published var items: Result<ESI.ContractItems, AFError>?
    @Published var bids: Result<ESI.ContractBids, AFError>?
    @Published var contacts: [Int64: Contact]?
    @Published var locations: [Int64: EVELocation]?
    
    init(esi: ESI, characterID: Int64, contract: ESI.PersonalContracts.Element, managedObjectContext: NSManagedObjectContext) {
        esi.characters.characterID(Int(characterID)).contracts().contractID(contract.contractID).bids().get()
            .asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.bids = result.map{$0.value}
        }.store(in: &subscriptions)

        esi.characters.characterID(Int(characterID)).contracts().contractID(contract.contractID).items().get()
            .asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.items = result.map{$0.value}
        }.store(in: &subscriptions)
        
        $bids.compactMap{$0}
            .tryGet()
            .replaceError(with: [])
            .flatMap { bids in
                Contact.contacts(with: Set(([contract.acceptorID, contract.assigneeID, contract.issuerID] + bids.map{$0.bidderID}).map{Int64($0)}),
                                 esi: esi,
                                 characterID: characterID,
                                 options: [.universe],
                                 managedObjectContext: managedObjectContext)

        }
        .receive(on: RunLoop.main)
        .sink { [weak self] result in
            self?.contacts = result
        }.store(in: &subscriptions)
        
        let locationIDs = [contract.startLocationID, contract.endLocationID].compactMap{$0}
        EVELocation.locations(with: Set(locationIDs), esi: esi, managedObjectContext: managedObjectContext)
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.locations = result
        }.store(in: &subscriptions)
    }
    
    var subscriptions = Set<AnyCancellable>()
}
