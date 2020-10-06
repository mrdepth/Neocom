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
    @EnvironmentObject private var sharedState: SharedState
    let require: [ESI.Scope] = [.esiWalletReadCharacterWalletV1]
    
    var body: some View {
        Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: WalletTransactions()) {
                    Icon(Image("journal"))
                    Text("Wallet Transactions")
                }
            }
        }
    }
}

#if DEBUG
struct WalletTransactionsItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                WalletTransactionsItem()
            }.listStyle(GroupedListStyle())
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
