//
//  LoyaltyPointsItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/28/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct LoyaltyPointsItem: View {
    @Environment(\.account) private var account
    let require: [ESI.Scope] = [.esiCharactersReadLoyaltyV1]
    
    var body: some View {
        Group {
            if account?.verifyCredentials(require) == true {
                NavigationLink(destination: LoyaltyPoints()) {
                    Icon(Image("lpstore"))
                    Text("Loyalty Points")
                }
            }
        }
    }
}

struct LoyaltyPointsItem_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        
        return NavigationView {
            List {
                LoyaltyPointsItem()
            }.listStyle(GroupedListStyle())
        }
        .environment(\.account, account)
        .environment(\.esi, esi)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
