//
//  WalletTransactions.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import CoreData
import Expressible

struct WalletTransactions: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState

    @ObservedObject var transactions: Lazy<WalletTransactionsData, Account> = Lazy()

    
    var body: some View {
        let result = sharedState.account.map { account in
            self.transactions.get(account, initial: WalletTransactionsData(esi: sharedState.esi, characterID: account.characterID, managedObjectContext: managedObjectContext))
        }
        let list = List {
            if result?.result?.value != nil {
                WalletTransactionsContent(transactions: result!.result!.value!.transactions,
                                          contacts: result!.result!.value!.contacts,
                                          locations: result!.result!.value!.locations)
            }
        }.listStyle(GroupedListStyle())
            .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay((result?.result?.error).map{Text($0)})
            .overlay(result?.result?.value?.transactions.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        
        return Group {
            if result != nil {
                list.onRefresh(isRefreshing: Binding(result!, keyPath: \.isLoading)) {
                    result?.update(cachePolicy: .reloadIgnoringLocalCacheData)
                }
            }
            else {
                list
            }
        }
        .navigationBarTitle(Text("Wallet Transactions"))

    }
}

struct WalletTransactionsContent: View {
    var transactions: ESI.WalletTransactions
    var contacts: [Int64: Contact]
    var locations: [Int64: EVELocation]
    
    private struct WalletTransactionsSection {
        var date: Date
        var transactions: ESI.WalletTransactions
    }

    
    var body: some View {
        let calendar = Calendar(identifier: .gregorian)

        let items = transactions.sorted{$0.date > $1.date}
        
        let sections = Dictionary(grouping: items, by: { (i) -> Date in
            let components = calendar.dateComponents([.year, .month, .day], from: i.date)
            return calendar.date(from: components) ?? i.date
        }).sorted {$0.key > $1.key}.map { (date, transactions) in
            WalletTransactionsSection(date: date, transactions: transactions)
        }

        return ForEach(sections, id: \.date) { section in
            Section(header: Text(DateFormatter.localizedString(from: section.date, dateStyle: .medium, timeStyle: .none).uppercased())) {
                ForEach(section.transactions, id: \.transactionID) { item in
                    WalletTransactionCell(item: item, contacts: self.contacts, locations: self.locations)
                }
            }
        }
    }
}

#if DEBUG
struct WalletTransactions_Previews: PreviewProvider {
    static var previews: some View {
        let contact = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.testStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact.name = "Artem Valiant"
        contact.contactID = 1554561480
        
        let solarSystem = try! Storage.testStorage.persistentContainer.viewContext.from(SDEMapSolarSystem.self).first()!
        let location = EVELocation(solarSystem: solarSystem, id: Int64(solarSystem.solarSystemID))
        
        
        let transactions = (0..<100).map { i in
            ESI.WalletTransactions.Element(clientID: Int(contact.contactID),
                                           date: Date(timeIntervalSinceNow: -3600 * TimeInterval(i) * 3),
                                           isBuy: true,
                                           isPersonal: true,
                                           journalRefID: 1,
                                           locationID: location.id,
                                           quantity: 2,
                                           transactionID: i,
                                           typeID: 645,
                                           unitPrice: 1000000)
        }
        
        return NavigationView {
//                        WalletTransactions()
            List {
                WalletTransactionsContent(transactions: transactions, contacts: [1554561480: contact], locations: [location.id: location])
            }.listStyle(GroupedListStyle())
                .navigationBarTitle(Text("Wallet Transactions"))
            
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
