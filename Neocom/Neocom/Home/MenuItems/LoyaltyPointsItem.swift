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
    @EnvironmentObject private var sharedState: SharedState
    let require: [ESI.Scope] = [.esiCharactersReadLoyaltyV1]
    
    var body: some View {
        Group {
            if sharedState.account?.verifyCredentials(require) == true {
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
        NavigationView {
            List {
                LoyaltyPointsItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
