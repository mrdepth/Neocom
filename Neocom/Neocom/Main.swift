//
//  Main.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct Main: View {
    var body: some View {
		NavigationView {
            Home()
            Text("Detail")
		}.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct Main_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return Main()
            .environment(\.account, account)
            .environment(\.esi, esi)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)

    }
}
