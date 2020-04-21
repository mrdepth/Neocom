//
//  PlanetariesItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/1/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct PlanetariesItem: View {
    @EnvironmentObject private var sharedState: SharedState
    let require: [ESI.Scope] = [.esiPlanetsManagePlanetsV1]
    
    var body: some View {
        Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: Planetaries()) {
                    Icon(Image("planets"))
                    Text("Planetaries")
                }
            }
        }
    }
}

struct PlanetariesItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                PlanetariesItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
