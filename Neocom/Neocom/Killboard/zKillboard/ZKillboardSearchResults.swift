//
//  ZKillboardSearchResults.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/4/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct ZKillboardSearchResults: View {
    var filter: [ZKillboard.Filter]
    
    @ObservedObject private var killmails = Lazy<ZKillboardLoader, Never>()
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.managedObjectContext) private var managedObjectContext
    private let cache = Cache<Int64, DataLoader<KillmailData, Never>>()

    var body: some View {
        let result = self.killmails.get(initial: ZKillboardLoader(filter: filter, esi: sharedState.esi, managedObjectContext: managedObjectContext))
        let contacts = result.contacts
        let killmails = result.killmails?.value
        
        return List {
            if killmails != nil {
                Section(footer: ActivityIndicatorView(style: .medium).frame(maxWidth: .infinity).padding().opacity(result.isLoading ? 1 : 0)) {
                    ForEach(killmails!) { killmail in
                        KillmailCell(killmail: killmail.result, contacts: contacts, cache: self.cache)
                            .onAppear {
                                if killmail.id == killmails?.last?.id {
                                    result.next()
                                }
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
            .overlay(result.killmails == nil && result.isLoading ? ActivityIndicatorView(style: .large) : nil)
        .overlay(result.killmails?.error.map{Text($0)})
        .overlay(killmails?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        .navigationBarTitle(Text("zKillboard"))
    }
}

#if DEBUG
struct ZKillboardSearchResults_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ZKillboardSearchResults(filter: [.kills, .solo])
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
#endif
