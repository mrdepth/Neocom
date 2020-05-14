//
//  AssetsItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct AssetsItem: View {
    @EnvironmentObject private var sharedState: SharedState
    let require: [ESI.Scope] = [.esiAssetsReadAssetsV1]
    
    var body: some View {
        Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: Assets()) {
                    Icon(Image("assets"))
                    Text("Assets")
                }
            }
        }
    }
}

#if DEBUG
struct AssetsItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                AssetsItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
#endif
