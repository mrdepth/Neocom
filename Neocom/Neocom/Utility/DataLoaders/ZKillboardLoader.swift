//
//  ZKillboardLoader.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/3/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Combine
import Alamofire
import CoreData

class ZKillboardLoader: ObservableObject {
    let zKillboard = ZKillboard()
    let filter: [ZKillboard.Filter]
    let esi: ESI
    let managedObjectContext: NSManagedObjectContext

    struct Record: Identifiable {
        var id: Int64
        var result: Result<ESI.Killmail, AFError>
    }

    
    @Published var killmails: Result<[Record], AFError>?
    @Published var contacts: [Int64: Contact] = [:]
    @Published var endReached = false
    @Published var page: Int = 1
    @Published var isLoading = false
    private var subscription: AnyCancellable?
    
    init(filter: [ZKillboard.Filter], esi: ESI, managedObjectContext: NSManagedObjectContext) {
        self.filter = filter
        self.esi = esi
        self.managedObjectContext = managedObjectContext
        load()
    }
    
    func next() {
        guard subscription == nil else {return}
        load()
    }

    private func load() {
        
        let esi = self.esi
        let managedObjectContext = self.managedObjectContext
        let zKillboard = self.zKillboard
        let filter = self.filter
        
        let loadKillmails = { (hashes: [ZKillboard.Killmail]) in
            Publishers.Sequence(sequence: hashes)
                .flatMap { killmail in
                    esi.killmails.killmailID(Int(killmail.killmailID)).killmailHash(killmail.hash).get()
                        .map{$0.value}
                        .asResult()
                        .map{Record(id: killmail.killmailID, result: $0)}
                    
            }.collect().setFailureType(to: AFError.self)
        }
        
        let loadContacts = { (contacts: [Int64: Contact], killmails: [Record]) -> AnyPublisher<[Int64: Contact], Never> in
            let kills = killmails.compactMap{$0.result.value}
            let ids = kills.flatMap {
                [$0.victim.characterID, $0.victim.corporationID, $0.victim.allianceID].compactMap{$0} +
                    $0.attackers.compactMap{$0.characterID} +
                    $0.attackers.compactMap{$0.corporationID} +
                    $0.attackers.compactMap{$0.allianceID}
            }
            let missing = Set(ids.map{Int64($0)}).subtracting(contacts.keys)
            return Contact.contacts(with: missing, esi: esi, characterID: nil, options: .universe, managedObjectContext: managedObjectContext).map { result in
                contacts.merging(result) { a, _ in a }
            }.eraseToAnyPublisher()
        }
        
        
        let load = { (page: Int, contacts: [Int64: Contact]) -> AnyPublisher<([Record], [Int64: Contact]), AFError> in
            zKillboard.kills.get(filter: filter, page: page)
                .map{$0.value}
                .flatMap(loadKillmails)
                .flatMap { killmails in
                    loadContacts(contacts, killmails).setFailureType(to: AFError.self).map { (killmails, $0) }
            }.eraseToAnyPublisher()
        }

        isLoading = true
        subscription = $endReached.zip($killmails, $page, $contacts).filter{!$0.0}
            .setFailureType(to: AFError.self)
            .flatMap { (_, killmails, page, contacts) in
                load(page, contacts)
                    .map { (newKillmails, contacts) in
                        (newKillmails.isEmpty, (killmails?.value ?? []) + newKillmails, page + 1, contacts)
                }
                .catch { error -> AnyPublisher<(Bool, [Record], Int, [Int64: Contact]), AFError> in
                    guard let value = killmails?.value else {return Fail(error: error).eraseToAnyPublisher()}
                    return Just((true, value, page, contacts)).setFailureType(to: AFError.self).eraseToAnyPublisher()
                }
        }
        .receive(on: RunLoop.main)
        .asResult()
        .sink { [weak self] result in
            let page = result.value?.2 ?? 1
            self?.isLoading = false
            self?.subscription = nil
            self?.endReached = (result.value?.0 ?? false) || page > 5
            self?.killmails = result.map{$0.1}
            self?.page = page
            self?.contacts = result.value?.3 ?? [:]
        }
    }
}
