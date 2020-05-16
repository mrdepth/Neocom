//
//  RecentKills.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct RecentKills: View {
    enum Filter {
        case kills
        case losses
    }
    
    @ObservedObject private var killmails = Lazy<KillmailsLoader, Account>()
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var filter: Filter = .kills
    private let cache = Cache<Int64, DataLoader<KillmailData, Never>>()
    
    private var picker: some View {
        Picker("Filter", selection: $filter) {
            Text("Kills").tag(Filter.kills)
            Text("Losses").tag(Filter.losses)
        }.pickerStyle(SegmentedPickerStyle())
    }

    var body: some View {
        let result = sharedState.account.map { self.killmails.get($0, initial: KillmailsLoader(esi: sharedState.esi, characterID: $0.characterID, managedObjectContext: managedObjectContext)) }
        let contacts = result?.contacts ?? [:]
        let killmails =  filter == .kills ? result?.killmails?.value?.kills : result?.killmails?.value?.losses
        
        return List {
            Section(header: picker, footer: ActivityIndicatorView(style: .medium).frame(maxWidth: .infinity).padding().opacity(killmails != nil && result?.isLoading == true ? 1 : 0)) {
                if killmails != nil {
                    RecentKillsPage(killmails: killmails!, contacts: contacts, cache: cache, result: result!)
                }
            }
        }.listStyle(GroupedListStyle())
            .overlay(result?.killmails == nil && result?.isLoading == true ? ActivityIndicatorView(style: .large) : nil)
        .overlay(result?.killmails?.error.map{Text($0)})
        .overlay(killmails?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        .navigationBarTitle("Kill Reports")
    }
}

struct RecentKillsPage: View {
    var killmails: [ESI.Killmail]
    var contacts: [Int64: Contact]
    var cache: Cache<Int64, DataLoader<KillmailData, Never>>
    var result: KillmailsLoader
    var body: some View {
        ForEach(killmails, id: \.killmailID) { killmail in
            KillmailCell(killmail: .success(killmail), contacts: self.contacts, cache: self.cache)
                .onAppear {
                    if killmail.killmailID == self.killmails.last?.killmailID {
                        self.result.next()
                    }
            }
        }
    }
}

#if DEBUG
struct RecentKills_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecentKills()
        }
            .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())

    }
}
#endif
