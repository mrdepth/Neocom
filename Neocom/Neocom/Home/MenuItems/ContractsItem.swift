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
    @EnvironmentObject private var sharedState: SharedState
    let require: [ESI.Scope] = [.esiContractsReadCharacterContractsV1]
    
    var body: some View {
        Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: Contracts()) {
                    Icon(Image("contracts"))
                    Text("Contracts")
                }
            }
        }
    }
}

#if DEBUG
struct ContractsItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                ContractsItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
#endif
