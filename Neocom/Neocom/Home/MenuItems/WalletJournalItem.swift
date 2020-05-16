//
//  WalletJournalItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct WalletJournalItem: View {
    @EnvironmentObject private var sharedState: SharedState
    let require: [ESI.Scope] = [.esiWalletReadCharacterWalletV1]
    
    var body: some View {
        Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: WalletJournal()) {
                    Icon(Image("wallet"))
                    Text("Wallet Journal")
                }
            }
        }
    }
}

#if DEBUG
struct WalletJournalItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                WalletJournalItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
#endif
