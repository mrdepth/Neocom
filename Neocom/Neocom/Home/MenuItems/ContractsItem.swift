//
//  ContractsItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct ContractsItem: View {
    @Environment(\.account) private var account
    let require: [ESI.Scope] = [.esiContractsReadCharacterContractsV1]
    
    var body: some View {
        Group {
            if account?.verifyCredentials(require) == true {
                NavigationLink(destination: Contracts()) {
                    Icon(Image("contracts"))
                    Text("Contracts")
                }
            }
        }
    }
}

struct ContractsItem_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        
        return NavigationView {
            List {
                ContractsItem()
            }.listStyle(GroupedListStyle())
        }
        .environment(\.account, account)
        .environment(\.esi, esi)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
