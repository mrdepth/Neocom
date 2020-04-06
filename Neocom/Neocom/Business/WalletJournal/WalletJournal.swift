//
//  WalletJournal.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire

struct WalletJournal: View {
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account

    @ObservedObject var journal: Lazy<DataLoader<ESI.WalletJournal, AFError>> = Lazy()
    
    private func journal(characterID: Int64) -> DataLoader<ESI.WalletJournal, AFError> {
        let publisher = esi.characters.characterID(Int(characterID)).wallet().journal().get()
            .map{$0.value}
            .receive(on: RunLoop.main)
        return DataLoader(publisher)
    }
    
    var body: some View {
        let journal = account.map { account in
            self.journal.get(initial: self.journal(characterID: account.characterID))
        }
        return List {
            if journal?.result?.value != nil {
                WalletJournalContent(journal: journal!.result!.value!)
            }
        }.listStyle(GroupedListStyle())
            .overlay(journal == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay((journal?.result?.error).map{Text($0)})
            .overlay(journal?.result?.value?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
            .navigationBarTitle(Text("Wallet Journal"))

    }
}

struct WalletJournalContent: View {
    var journal: ESI.WalletJournal

    private struct JournalSection {
        var date: Date
        var journal: ESI.WalletJournal
    }

    var body: some View {
        let calendar = Calendar(identifier: .gregorian)

        let items = journal.sorted{$0.date > $1.date}
        
        let sections = Dictionary(grouping: items, by: { (i) -> Date in
            let components = calendar.dateComponents([.year, .month, .day], from: i.date)
            return calendar.date(from: components) ?? i.date
        }).sorted {$0.key > $1.key}.map { (date, journal) in
            JournalSection(date: date, journal: journal)
        }

        return ForEach(sections, id: \.date) { section in
            Section(header: Text(DateFormatter.localizedString(from: section.date, dateStyle: .medium, timeStyle: .none).uppercased())) {
                ForEach(section.journal, id: \.id) { item in
                    WalletJournalCell(item: item)
                }
            }
        }
    }
}

struct WalletJournal_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        
        let journal = (0..<100).map { i in
            ESI.WalletJournal.Element(amount: 1000,
                                      balance: 10000,
                                      contextID: 1554561480,
                                      contextIDType: .characterID,
                                      date: Date(timeIntervalSinceNow: -3600 * TimeInterval(i) * 3),
                                      localizedDescription: "Description",
                                      firstPartyID: 1554561480,
                                      id: i,
                                      reason: "Reason",
                                      refType: .agentDonation,
                                      secondPartyID: 1554561480,
                                      tax: 10,
                                      taxReceiverID: 1554561480)
        }
        
        return NavigationView {
            List {
                WalletJournalContent(journal: journal)
            }.listStyle(GroupedListStyle())
            .navigationBarTitle(Text("Wallet Journal"))
            
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.account, account)
        .environment(\.esi, esi)
    }
}
