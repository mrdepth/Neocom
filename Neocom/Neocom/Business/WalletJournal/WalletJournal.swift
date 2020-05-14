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
import Combine

struct WalletJournal: View {
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState

    @ObservedObject var journal: Lazy<DataLoader<ESI.WalletJournal, AFError>, Account> = Lazy()
    
    private func getJournal(characterID: Int64, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> AnyPublisher<ESI.WalletJournal, AFError> {
        sharedState.esi.characters.characterID(Int(characterID)).wallet().journal().get(cachePolicy: cachePolicy)
            .map{$0.value}
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    var body: some View {
        let result = sharedState.account.map { account in
            self.journal.get(account, initial: DataLoader(self.getJournal(characterID: account.characterID)))
        }
        let list = List {
            if result?.result?.value != nil {
                WalletJournalContent(journal: result!.result!.value!)
            }
        }
        .listStyle(GroupedListStyle())
        .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
        .overlay((result?.result?.error).map{Text($0)})
        .overlay(result?.result?.value?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        
        return Group {
            if result != nil {
                list.onRefresh(isRefreshing: Binding(result!, keyPath: \.isLoading)) {
                    guard let account = self.sharedState.account else {return}
                    result?.update(self.getJournal(characterID: account.characterID, cachePolicy: .reloadIgnoringLocalCacheData))
                }
            }
            else {
                list
            }
        }
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

#if DEBUG
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
        .environmentObject(SharedState.testState())
    }
}
#endif
