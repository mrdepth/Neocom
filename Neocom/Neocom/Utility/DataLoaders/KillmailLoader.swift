//
//  KillmailLoader.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/3/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import CoreData
import Alamofire

class KillmailLoader: ObservableObject {
    
    @Published var result: Result<(ESI.Killmail, [Int64: Contact]), AFError>?
    
    private var subscription: AnyCancellable?
    
    init(esi: ESI, killmailID: Int64, hash: String, managedObjectContext: NSManagedObjectContext) {
        
        let getContacts = {(killmail: ESI.Killmail) -> AnyPublisher<[Int64: Contact], Never> in
            let ids = [killmail.victim.characterID, killmail.victim.corporationID, killmail.victim.allianceID].compactMap{$0} +
                killmail.attackers.compactMap{$0.characterID} +
                killmail.attackers.compactMap{$0.corporationID} +
                killmail.attackers.compactMap{$0.allianceID}
            return Contact.contacts(with: Set(ids.map{Int64($0)}), esi: esi, characterID: nil, options: [.universe], managedObjectContext: managedObjectContext)
        }
        
        subscription = esi.killmails.killmailID(Int(killmailID)).killmailHash(hash).get().map{$0.value}
        .flatMap { killmail -> AnyPublisher<(ESI.Killmail, [Int64: Contact]), AFError> in
            getContacts(killmail)
                .setFailureType(to: AFError.self)
                .map { (killmail, $0) }
                .eraseToAnyPublisher()
        }
        .asResult()
        .receive(on: RunLoop.main)
        .sink { [weak self] result in
            self?.result = result
        }
        
    }

}
