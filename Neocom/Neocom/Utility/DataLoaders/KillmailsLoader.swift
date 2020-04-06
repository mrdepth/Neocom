//
//  KillmailsLoader.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import CoreData
import Alamofire

class KillmailsLoader: ObservableObject {
    let esi: ESI
    let managedObjectContext: NSManagedObjectContext
    let characterID: Int64

    struct Record: Identifiable {
        var id: Int64
        var result: Result<ESI.Killmail, AFError>
    }

    
    @Published var killmails: Result<(kills: [ESI.Killmail], losses: [ESI.Killmail]), AFError>?
    @Published var contacts: [Int64: Contact] = [:]
    @Published var endReached = false
    @Published var page: Int = 1
    @Published var isLoading = false
    private var subscription: AnyCancellable?
    
    init(esi: ESI, characterID: Int64, managedObjectContext: NSManagedObjectContext) {
        self.esi = esi
        self.managedObjectContext = managedObjectContext
        self.characterID = characterID
        load()
    }
    
    func next() {
        guard subscription == nil else {return}
        load()
    }

    private func load() {
        
        let esi = self.esi
        let characterID = self.characterID
        let managedObjectContext = self.managedObjectContext
        
        let loadKillmails = { (hashes: [ESI.KillmailHash]) in
            Publishers.Sequence(sequence: hashes)
                .flatMap { killmail in
                    esi.killmails.killmailID(Int(killmail.killmailID)).killmailHash(killmail.killmailHash).get()
                        .map{$0.value}
                        .catch { _ in
                            Empty()
                    }
                    
            }.collect().setFailureType(to: AFError.self)
        }
        
        let loadContacts = { (contacts: [Int64: Contact], killmails: [ESI.Killmail]) -> AnyPublisher<[Int64: Contact], Never> in
            let ids = killmails.flatMap {
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
        
        
        let load = { (page: Int, contacts: [Int64: Contact]) -> AnyPublisher<([ESI.Killmail], [Int64: Contact]), AFError> in
            esi.characters.characterID(Int(characterID)).killmails().recent().get(page: page)
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
                    .map { (newKillmails, contacts) -> (Bool, (kills: [ESI.Killmail], losses: [ESI.Killmail]), Int, [Int64: Contact]) in
                        var newKillmails = newKillmails
                        let i = newKillmails.partition{$0.victim.characterID == Int(characterID)}
                        return (newKillmails.isEmpty,
                                (kills: (killmails?.value?.kills ?? []) + newKillmails[..<i], losses: (killmails?.value?.losses ?? []) + newKillmails[i...]),
                                page + 1,
                                contacts: contacts)
                        
                }
                .catch { error -> AnyPublisher<(Bool, (kills: [ESI.Killmail], losses: [ESI.Killmail]), Int, [Int64: Contact]), AFError> in
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
