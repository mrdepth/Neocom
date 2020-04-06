//
//  WalletTransactionsItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct WalletTransactionsItem: View {
    @Environment(\.account) private var account
    let require: [ESI.Scope] = [.esiWalletReadCharacterWalletV1]
    
    var body: some View {
        Group {
            if account?.verifyCredentials(require) == true {
                NavigationLink(destination: WalletTransactions()) {
                    Icon(Image("journal"))
                    Text("Wallet Transactions")
                }
            }
        }
    }
}

struct WalletTransactionsItem_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        
        return NavigationView {
            List {
                WalletTransactionsItem()
            }.listStyle(GroupedListStyle())
        }
        .environment(\.account, account)
        .environment(\.esi, esi)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
