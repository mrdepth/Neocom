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
    private enum HeaderFrame {}
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.account) private var account
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    
    @State private var isAccountsPresented = false
    @State private var navigationAvatarItemVisible = false
    @UserDefault(key: .activeAccountID) private var accountID: String? = nil
    
    private let headerContent = HomeHeader()
    private let serverStatus = ServerStatus()
    private let characterSheet = CharacterSheetItem()
    private let jumpClones = JumpClonesItem()
    private let skills = SkillsItem()
    private let wealth = WealthMenuItem()
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                self.isAccountsPresented = true
            }) {
                headerContent
            }.buttonStyle(PlainButtonStyle())
            serverStatus.frame(maxWidth: .infinity, alignment: .leading).padding(4)
        }
    }
    
    private var navigationAvatarItem: some View {
        account.map{ account in
            Group {
                if navigationAvatarItemVisible {
                    Button(action: {
                        self.isAccountsPresented = true
                    }) {
                        Avatar(characterID: account.characterID, size: .size256).frame(width: 36, height: 36)
                            .animation(.linear)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                self.header//.framePreference(in: .global, HeaderFrame.self)
                    .anchorPreference(key: AppendPreferenceKey<CGRect, HeaderFrame>.self, value: Anchor<CGRect>.Source.bounds) {
                        [geometry[$0]]
                }
//                    .background(GeometryReader { geometry in
//                        Color.clear.preference(key: AppendPreferenceKey<CGRect, HeaderFrame>.self, value: [geometry.frame(in: .global).offsetBy(dx: 0, dy: -geometry.safeAreaInsets.top)])
//                    })

                Section(header: Text("CHARACTER")) {
                    self.characterSheet
                    self.jumpClones
                    self.skills
                    MailItem()
                    CalendarItem()
                    self.wealth
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
                
                Section(header: Text("FITTING")) {
                    FittingItem()
                }
                
            }.listStyle(GroupedListStyle())
                
        }.sheet(isPresented: $isAccountsPresented) {
            NavigationView {
                Accounts { account in
                    if self.sharedState.account != account {
                        self.sharedState.account = account
                    }
//                    if self.accountID != account.uuid {
//                        self.accountID = account.uuid
//                    }
                    self.isAccountsPresented = false
                }
                .navigationBarItems(leading: Button("Close") {
                    self.isAccountsPresented = false
                }, trailing: EditButton())
                    
            }.modifier(ServicesViewModifier(environment: self.environment))
        }
//        .navigationBarTitle("Neocom")
//        .navigationBarHidden(true)
            .navigationBarTitle(account?.characterName ?? "Neocom")
            .navigationBarItems(leading: navigationAvatarItem, trailing: account != nil ? Button("Logout") {self.accountID = nil} : nil)
            .onFrameChange(HeaderFrame.self) { frame in
                self.navigationAvatarItemVisible = (frame.first?.minY ?? -100) < -35
        }
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
