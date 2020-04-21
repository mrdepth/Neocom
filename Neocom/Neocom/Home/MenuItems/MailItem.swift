//
//  MailItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct MailItem: View {
    @EnvironmentObject private var sharedState: SharedState

    let require: [ESI.Scope] = [.esiMailReadMailV1,
                                .esiMailSendMailV1,
                                .esiMailOrganizeMailV1]

    var body: some View {
        Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: MailBox()) {
                    Icon(Image("evemail"))
                    Text("EVE Mail")
                }
            }
        }
    }
}

struct MailItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                MailItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
