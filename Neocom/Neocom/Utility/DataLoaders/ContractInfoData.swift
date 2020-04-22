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
    @Published var isLoading = false
    @Published var items: Result<ESI.ContractItems, AFError>?
    @Published var bids: Result<ESI.ContractBids, AFError>?
    @Published var contacts: [Int64: Contact]?
    @Published var locations: [Int64: EVELocation]?
    
    private var esi: ESI
    private var characterID: Int64
    private var contract: ESI.PersonalContracts.Element
    private var managedObjectContext: NSManagedObjectContext

    
    init(esi: ESI, characterID: Int64, contract: ESI.PersonalContracts.Element, managedObjectContext: NSManagedObjectContext) {
        self.esi = esi
        self.characterID = characterID
        self.managedObjectContext = managedObjectContext
        self.contract = contract
        update(cachePolicy: .useProtocolCachePolicy)
    }
    
    func update(cachePolicy: URLRequest.CachePolicy) {
        isLoading = true
        subscriptions.removeAll()
        let contract = self.contract
        let managedObjectContext = self.managedObjectContext
        let esi = self.esi
        let characterID = self.characterID
        
        let bids = esi.characters.characterID(Int(characterID)).contracts().contractID(contract.contractID).bids().get(cachePolicy: cachePolicy).share()
        
        Publishers.Zip(
            bids,
            esi.characters.characterID(Int(characterID)).contracts().contractID(contract.contractID).items().get(cachePolicy: cachePolicy))
            .asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.bids = result.map{$0.0.value}
                self?.items = result.map{$0.1.value}
                self?.isLoading = false
        }.store(in: &subscriptions)

        bids.map{$0.value}
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
