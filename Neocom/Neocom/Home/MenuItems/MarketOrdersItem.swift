//
//  MarketOrdersItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct MarketOrdersItem: View {
    @EnvironmentObject private var sharedState: SharedState
    let require: [ESI.Scope] = [.esiMarketsReadCharacterOrdersV1]
    
    var body: some View {
        Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: MarketOrders()) {
                    Icon(Image("marketdeliveries"))
                    Text("Market Orders")
                }
            }
        }
    }
}

struct MarketOrdersItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                MarketOrdersItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
