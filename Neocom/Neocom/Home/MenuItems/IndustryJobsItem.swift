//
//  IndustryJobsItems.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct IndustryJobsItem: View {
    @EnvironmentObject private var sharedState: SharedState
    let require: [ESI.Scope] = [.esiIndustryReadCharacterJobsV1]
    
    var body: some View {
        Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: IndustryJobs()) {
                    Icon(Image("industry"))
                    Text("Industry Jobs")
                }
            }
        }
    }
}

struct IndustryJobsItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                IndustryJobsItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
