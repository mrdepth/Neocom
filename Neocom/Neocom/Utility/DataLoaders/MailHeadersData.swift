//
//  MailHeadersData.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Combine
import Alamofire
import CoreData

class MailHeadersData: ObservableObject {
    struct Section {
        var date: Date
        var mails: ESI.MailHeaders
    }
    
    @Published var sections: Result<[Section], AFError>?
    @Published var contacts: [Int64: Contact?] = [:]
    private var esi: ESI
    private var characterID: Int64
    private var labelID: Int
    private var managedObjectContext: NSManagedObjectContext
    @Published var endReached = false
    
    init(esi: ESI, characterID: Int64, labelID: Int, managedObjectContext: NSManagedObjectContext) {
        self.esi = esi
        self.characterID = characterID
        self.labelID = labelID
        self.managedObjectContext = managedObjectContext
        load()
    }
    
    func next() {
        guard subscription == nil else {return}
        load()
    }
    
    func delete(mailIDs: Set<Int>) {
        guard var sections = sections?.value else {return}
        for i in sections.indices {
            sections[i].mails.removeAll{mailIDs.contains($0.mailID ?? -1)}
        }
        
        self.sections = .success(sections.filter{!$0.mails.isEmpty})
    }
    
    private func load() {
        
        subscription = Publishers.Zip3($endReached, $sections, $contacts).filter{!$0.0}
            .setFailureType(to: AFError.self)
            .flatMap { [esi, labelID, characterID, managedObjectContext] (_, sections, contacts) in
                esi.characters.characterID(Int(characterID)).mail().get(labels: [labelID],
                                                                        lastMailID: sections?.value?.last?.mails.last?.mailID)
                    .receive(on: DispatchQueue.global(qos: .utility))
                    .flatMap { result -> AnyPublisher<([Int64: Contact?], [Section]), AFError> in
                        let calendar = Calendar(identifier: .gregorian)
                        let mails = result.value.filter{$0.timestamp != nil}
                        let items = mails.sorted{$0.timestamp! > $1.timestamp!}
                        
                        let sections = Dictionary(grouping: items, by: { (i) -> Date in
                            let components = calendar.dateComponents([.year, .month, .day], from: i.timestamp!)
                            return calendar.date(from: components) ?? i.timestamp!
                        }).sorted {$0.key > $1.key}.map { (date, mails) in
                            Section(date: date, mails: mails)
                        }
                        

                        var contactIDs = Set((mails.compactMap{$0.from} + mails.flatMap{$0.recipients?.map{$0.recipientID} ?? []}).map{Int64($0)})
                        contactIDs.subtract(contacts.keys)
                        return Contact.contacts(with: contactIDs, esi: esi, characterID: characterID, options: [.all], managedObjectContext: managedObjectContext)
                            .map { $0.mapValues{$0 as Optional}.merging(contactIDs.map{($0, nil)}, uniquingKeysWith: {a, b in a ?? b}) }
                            .zip(Just(sections))
                            .setFailureType(to: AFError.self)
                            .eraseToAnyPublisher()
                }.map { (newContacts, newSections) -> ([Int64: Contact?], [Section], Bool) in
                    (newContacts.merging(contacts, uniquingKeysWith: {a, b in a ?? b}), merge((sections?.value ?? []), newSections), newSections.isEmpty)
                }
                .catch { error -> AnyPublisher<([Int64: Contact?], [Section], Bool), AFError> in
                    guard let value = sections?.value else {return Fail(error: error).eraseToAnyPublisher()}
                    return Just((contacts, value, true)).setFailureType(to: AFError.self).eraseToAnyPublisher()
                }
        }.receive(on: RunLoop.main)
            .asResult()
            .sink { [weak self] result in
                self?.subscription = nil
                self?.contacts = result.value?.0 ?? [:]
                self?.sections = result.map{$0.1}
                self?.endReached = result.value?.2 ?? true
        }
    }
    
    private var subscription: AnyCancellable?
}


fileprivate func merge (_ lhs: [MailHeadersData.Section], _ rhs: [MailHeadersData.Section]) -> [MailHeadersData.Section] {
    var out = [MailHeadersData.Section]()
    out.reserveCapacity(lhs.count + rhs.count)
    
    var i = lhs.makeIterator()
    var j = rhs.makeIterator()
    var a = i.next()
    var b = j.next()
    
    while a != nil && b != nil {
        if a!.date > b!.date {
            out.append(a!)
            a = i.next()
        }
        else if a!.date < b!.date {
            out.append(b!)
            b = j.next()
        }
        else {
            out.append(MailHeadersData.Section(date: a!.date, mails: a!.mails + b!.mails))
            a = i.next()
            b = j.next()
        }
    }
    while a != nil {
        out.append(a!)
        a = i.next()
    }
    while b != nil {
        out.append(b!)
        b = j.next()
    }
    return out
}
