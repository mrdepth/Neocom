//
//  RecentKillsItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/6/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct RecentKillsItem: View {
    @EnvironmentObject private var sharedState: SharedState
    let require: [ESI.Scope] = [.esiKillmailsReadKillmailsV1]
    
    var body: some View {
        Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: RecentKills()) {
                    Icon(Image("killreport"))
                    Text("Kill Reports")
                }
            }
        }
    }
}

#if DEBUG
struct RecentKillsItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                RecentKillsItem()
            }.listStyle(GroupedListStyle())
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
