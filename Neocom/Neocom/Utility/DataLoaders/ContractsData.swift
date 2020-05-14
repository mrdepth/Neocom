//
//  ContractsData.swift
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

class ContractsData: ObservableObject {
    @Published var isLoading = false
    @Published var result: Result<(open: ESI.PersonalContracts, closed: ESI.PersonalContracts, contacts: [Int64: Contact], locations: [Int64: EVELocation]), AFError>?
    
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

        subscription = esi.characters.characterID(Int(characterID)).contracts().get(cachePolicy: cachePolicy).flatMap { contracts -> AnyPublisher<(ESI.PersonalContracts, ESI.PersonalContracts, [Int64: Contact], [Int64: EVELocation]), AFError> in
            let clientIDs = contracts.value.map{Int64($0.issuerID)}
            let locationIDs = contracts.value.compactMap{$0.startLocationID}
            let contacts = Contact.contacts(with: Set(clientIDs), esi: esi, characterID: characterID, options: [.universe], managedObjectContext: managedObjectContext).replaceError(with: [:])
            let locations = EVELocation.locations(with: Set(locationIDs), esi: esi, managedObjectContext: managedObjectContext).replaceError(with: [:])
            
            var tmp = contracts.value
            let i = tmp.partition{$0.isOpen}
            let open = tmp[i...].sorted{$0.dateExpired < $1.dateExpired}
            let closed = tmp[..<i].sorted{$0.dateExpired > $1.dateExpired}

            return Publishers.Zip4(Just(open), Just(closed), contacts, locations).setFailureType(to: AFError.self).eraseToAnyPublisher()
        }.asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.result = result.map{(open: $0.0, closed: $0.1, contacts: $0.2, locations: $0.3)}
                self?.isLoading = false
        }
    }
}
