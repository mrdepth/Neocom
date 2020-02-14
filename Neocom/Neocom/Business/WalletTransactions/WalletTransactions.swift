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
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account

    @ObservedObject var transactions: Lazy<WalletTransactionsData> = Lazy()

    
    var body: some View {
        let transactions = account.map { account in
            self.transactions.get(initial: WalletTransactionsData(esi: esi, characterID: account.characterID, managedObjectContext: managedObjectContext))
        }
        return List {
            if transactions?.result?.value != nil {
                WalletTransactionsContent(transactions: transactions!.result!.value!.transactions,
                                          contacts: transactions!.result!.value!.contacts,
                                          locations: transactions!.result!.value!.locations)
            }
        }.listStyle(GroupedListStyle())
            .overlay(transactions == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay((transactions?.result?.error).map{Text($0)})
            .overlay(transactions?.result?.value?.transactions.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
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

struct WalletTransactions_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        let contact = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: AppDelegate.sharedDelegate.persistentContainer.viewContext)!, insertInto: nil)
        contact.name = "Artem Valiant"
        contact.contactID = 1554561480
        
        let solarSystem = try! AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEMapSolarSystem.self).first()!
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
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.account, account)
        .environment(\.esi, esi)
    }
}
