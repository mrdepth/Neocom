//
//  Home.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire

struct Home: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.account) var account
    
    @State var accountsVisible = false
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                self.accountsVisible = true
            }) {
                HomeHeader()
            }.buttonStyle(PlainButtonStyle())
            Divider()
            ServerStatus().frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal).padding(.vertical, 4)
            Divider()
            
            List {
                Section(header: Text("CHARACTER")) {
                    CharacterSheetItem()
                    JumpClonesItem()
                    SkillsItem()
                    MailItem()
                    CalendarItem()
                    WealthMenuItem()
                    LoyaltyPointsItem()
                }
                Section(header: Text("DATABASE")) {
                    DatabaseItem()
                    CertificatesItem()
                    MarketItem()
                    NPCItem()
                    WormholesItem()
                    IncursionsItem()
                }
                
                Section(header: Text("BUSINESS")) {
                    AssetsItem()
                    MarketOrdersItem()
                    ContractsItem()
                    WalletTransactionsItem()
                    WalletJournalItem()
                    IndustryJobsItem()
                    PlanetariesItem()
                }
                
                Section(header: Text("KILLBOARD")) {
                    RecentKillsItem()
                    ZKillboardItem()
                }
                
            }.listStyle(GroupedListStyle())
        }.sheet(isPresented: $accountsVisible) {
            NavigationView {
                Accounts().navigationBarItems(leading: Button("Cancel") {
                    self.accountsVisible = false
                }).environment(\.managedObjectContext, self.managedObjectContext)
            }
        }
        .navigationBarTitle("Neocom")
//        .navigationBarHidden(true)
//            .navigationBarTitle(account?.characterName ?? "Neocom")
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return NavigationView {
            Home()
        }
        .environment(\.account, account)
        .environment(\.esi, esi)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())

    }
}
