//
//  Contact+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import CoreData
import Combine
import Alamofire
import Expressible

extension Contact {
    private struct PartialResult {
        var contacts: [Int64: Contact]
        var missingIDs: Set<Int64>
    }
    
    struct SearchOptions: OptionSet {
        let rawValue: Int
        static let universe = SearchOptions(rawValue: 1 << 0)
        static let mailingLists = SearchOptions(rawValue: 1 << 1)
        
        static let all: SearchOptions = [.universe, .mailingLists]
    }
        
    static func contacts(with contactIDs: Set<Int64>, esi: ESI, characterID: Int64?, options: SearchOptions, managedObjectContext: NSManagedObjectContext) -> AnyPublisher<[Int64: Contact], Never> {

        var missing = contactIDs
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = managedObjectContext
        
        guard !missing.isEmpty else {return Just([:]).eraseToAnyPublisher()}
        
        
        func localContact(_ missingIDs: Set<Int64>) -> Future<PartialResult, Never> {
            Future { promise in
                backgroundContext.perform {
                    let result = (try? Dictionary(backgroundContext.from(Contact.self)
                        .filter((/\Contact.contactID).in(missing))
                        .fetch()
                        .map{($0.contactID, $0)}) {a, _ in a}) ?? [:]
                    promise(.success(PartialResult(contacts: result, missingIDs: missingIDs.subtracting(result.keys))))
                }
            }
        }
        
        func mailingLists(_ result: PartialResult) -> AnyPublisher<PartialResult, Never> {
            guard let characterID = characterID, !result.missingIDs.isEmpty, options.contains(.mailingLists) else {return Just(result).eraseToAnyPublisher()}
            return esi.characters.characterID(Int(characterID)).mail().lists().get().receive(on: backgroundContext).map { mailingLists -> PartialResult in
                let ids = mailingLists.value.map{$0.mailingListID}
                guard !ids.isEmpty else {return result}
                let existing = (try? backgroundContext.from(Contact.self).filter((/\Contact.contactID).in(ids)).fetch()) ?? []
                let existingIDs = Set(existing.map{$0.contactID})
                let new = mailingLists.value.filter{!existingIDs.contains(Int64($0.mailingListID))}.map { mailingList -> Contact in
                    let contact = Contact(context: backgroundContext)
                    contact.contactID = Int64(mailingList.mailingListID)
                    contact.category = ESI.RecipientType.mailingList.rawValue
                    contact.name = mailingList.name
                    return contact
                }
                let contacts = (existing + new).filter{result.missingIDs.contains($0.contactID)}
                let missing = result.missingIDs.subtracting(contacts.map{$0.contactID})
                let mergedContacts = result.contacts.merging(contacts.map{($0.contactID, $0)}) {a, _ in a}
                return PartialResult(contacts: mergedContacts, missingIDs: missing)
            }.replaceError(with: result)
                .eraseToAnyPublisher()
        }
        
        func universeNames(_ result: PartialResult) -> AnyPublisher<PartialResult, Never> {
            guard !result.missingIDs.isEmpty, options.contains(.universe) else {return Just(result).eraseToAnyPublisher()}
            return esi.universe.names().post(ids: result.missingIDs.compactMap{Int(exactly: $0)}).receive(on: backgroundContext).map { names ->PartialResult in
                let contacts = names.value.map { name -> Contact in
                    let contact = Contact(context: backgroundContext)
                    contact.contactID = Int64(name.id)
                    contact.category = name.category.rawValue
                    contact.name = name.name
                    return contact
                }
                let missing = result.missingIDs.subtracting(contacts.map{$0.contactID})
                let mergedContacts = result.contacts.merging(contacts.map{($0.contactID, $0)}) {a, _ in a}
                return PartialResult(contacts: mergedContacts, missingIDs: missing)
            }.replaceError(with: result)
                .eraseToAnyPublisher()
        }
        
        return localContact(missing)
            .flatMap { mailingLists($0) }
            .flatMap { universeNames($0) }
            .receive(on: backgroundContext)
            .map { result -> [Int64: NSManagedObjectID] in
                var contacts = result.contacts
                
                while true {
                    do {
                        try backgroundContext.save()
                        break
                    }
                    catch {
                        guard let error = error as? CocoaError, error.errorCode == CocoaError.managedObjectConstraintMerge.rawValue else {break}
                        guard let conflicts = error.errorUserInfo[NSPersistentStoreSaveConflictsErrorKey] as? [NSConstraintConflict], !conflicts.isEmpty else {break}
                        let pairs = conflicts.filter{$0.databaseObject is Contact}.map { conflict in
                            (conflict.databaseObject as! Contact, Set(conflict.conflictingObjects.compactMap{$0 as? Contact}))
                        }.filter{!$0.1.isEmpty}
                        
                        if !pairs.isEmpty {
                            for (object, objects) in pairs {
                                contacts.filter{objects.contains($0.value)}.forEach {
                                    contacts[$0.key] = object
                                }
                                objects.forEach {
                                    $0.managedObjectContext?.delete($0)
                                }
                            }
                        }
                        else {
                            break
                        }
                    }
                }
                
                return contacts.mapValues{$0.objectID}
        }.receive(on: managedObjectContext)
            .map {
                $0.compactMapValues{try? managedObjectContext.existingObject(with: $0) as? Contact}
        }.eraseToAnyPublisher()
    }
    
    static func searchContacts(containing string: String, esi: ESI, options: SearchOptions, managedObjectContext: NSManagedObjectContext) -> AnyPublisher<[Contact], Never> {
        let s = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else {return Just([]).eraseToAnyPublisher()}
        
        let contacts = try? managedObjectContext.from(Contact.self).filter((/\Contact.name).caseInsensitive.contains(s))
            .fetch()
        
        let searchResults: AnyPublisher<[Contact], Never>
        if s.count < 3 {
            searchResults = Empty().eraseToAnyPublisher()
        }
        else {
            searchResults = esi.search.get(categories: [.character, .corporation, .alliance], search: s).map {$0.value}.map {
                Set([$0.character, $0.corporation, $0.alliance].compactMap{$0}.joined().map{Int64($0)})
            }.flatMap { ids in
                Contact.contacts(with: ids, esi: esi, characterID: nil, options: [.universe], managedObjectContext: managedObjectContext)
                    .map{Array($0.values)}
                    .setFailureType(to: AFError.self)
            }.catch{_ in Empty()}
                .eraseToAnyPublisher()
            
        }
        return Just(contacts ?? []).merge(with: searchResults).eraseToAnyPublisher()
    }
}
