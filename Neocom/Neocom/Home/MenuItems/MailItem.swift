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
    @Environment(\.account) private var account

    let require: [ESI.Scope] = [.esiMailReadMailV1,
                                .esiMailSendMailV1,
                                .esiMailOrganizeMailV1]

    var body: some View {
        Group {
            if account?.verifyCredentials(require) == true {
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
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        
        return NavigationView {
            List {
                MailItem()
            }.listStyle(GroupedListStyle())
        }
        .environment(\.account, account)
        .environment(\.esi, esi)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
