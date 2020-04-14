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
    
    @ObservedObject private var killmails = Lazy<ZKillboardLoader>()
    @Environment(\.esi) private var esi
    @Environment(\.managedObjectContext) private var managedObjectContext
    private let cache = Cache<Int64, DataLoader<KillmailData, Never>>()

    var body: some View {
        let result = self.killmails.get(initial: ZKillboardLoader(filter: filter, esi: esi, managedObjectContext: managedObjectContext))
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
        .navigationBarTitle("zKillboard")
    }
}

struct ZKillboardSearchResults_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ZKillboardSearchResults(filter: [.kills, .solo])
        }
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
    }
}
