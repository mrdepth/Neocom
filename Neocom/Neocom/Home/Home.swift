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
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    
    @State private var isAccountsPresented = false
    @State private var navigationAvatarItemVisible = false
//    @UserDefault(key: .activeAccountID) private var accountID: String? = nil
    
    private let headerContent = HomeHeader()
    private let serverStatus = ServerStatus()
    private let characterSheet = CharacterSheetItem()
    private let jumpClones = JumpClonesItem()
    private let skills = SkillsItem()
    private let wealth = WealthMenuItem()
    
    private var header: some View {
        Button(action: {
            self.isAccountsPresented = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                headerContent
                serverStatus.padding(4)
            }.contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
    }
    
    private var navigationAvatarItem: some View {
        Group {
            if navigationAvatarItemVisible {
                Button(action: {
                    self.isAccountsPresented = true
                }) {
                    if sharedState.account != nil {
                        Avatar(characterID: sharedState.account!.characterID, size: .size256).frame(width: 36, height: 36)
                            .animation(.linear)
                    }
                    else {
                        Avatar(image: nil)
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "person").resizable().padding(10))
                            .foregroundColor(.secondary)
                            .animation(.linear)
                    }
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    var body: some View {
//        GeometryReader { geometry in
            List {
                self.header.framePreference(in: .global, HeaderFrame.self)

                if sharedState.account != nil {
                    Section(header: Text("CHARACTER")) {
                        self.characterSheet
                        self.jumpClones
                        self.skills
                        MailItem()
                        CalendarItem()
                        self.wealth
                        LoyaltyPointsItem()
                    }
                }
                Section(header: Text("DATABASE")) {
                    DatabaseItem()
                    CertificatesItem()
                    MarketItem()
                    NPCItem()
                    WormholesItem()
                    IncursionsItem()
                }
                
                if sharedState.account != nil {
                    Section(header: Text("BUSINESS")) {
                        AssetsItem()
                        MarketOrdersItem()
                        ContractsItem()
                        WalletTransactionsItem()
                        WalletJournalItem()
                        IndustryJobsItem()
                        PlanetariesItem()
                    }
                }
                
                Section(header: Text("KILLBOARD")) {
                    RecentKillsItem()
                    ZKillboardItem()
                }
                
                Section(header: Text("FITTING")) {
                    FittingItem()
                }
                
                Section {
                    SettingsItem()
                    AboutItem()
                    #if !targetEnvironment(macCatalyst)
                    RemoveAdsItem()
                    #endif
                }
            }.listStyle(GroupedListStyle())
                
//        }
    .sheet(isPresented: $isAccountsPresented) {
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
                .navigationBarItems(leading: BarButtonItems.close {
                    self.isAccountsPresented = false
                }, trailing: EditButton())
                    
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
//        .navigationBarTitle(Text("Neocom"))
//        .navigationBarHidden(true)
            .navigationBarTitle(sharedState.account?.characterName ?? "Neocom")
            .navigationBarItems(leading: navigationAvatarItem, trailing: sharedState.account != nil ? Button(NSLocalizedString("Logout", comment: "")) {self.sharedState.account = nil} : nil)
            .onFrameChange(HeaderFrame.self) { frame in
                self.navigationAvatarItemVisible = (frame.first?.minY ?? -100) < -35
        }
    }
}

#if DEBUG
struct Home_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Home()
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
//        x§.environment(\.locale, Locale(identifier: "ru_RU"))
    }
}
#endif
