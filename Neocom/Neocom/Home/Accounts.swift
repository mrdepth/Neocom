//
//  Accounts.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import EVEAPI

struct Accounts: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Account.characterName, ascending: true)])
    var accounts: FetchedResults<Account>
    
    var body: some View {
        NavigationView {
            List {
                Button("Add new account") {
                    
                }
                Section {
                    ForEach(accounts, id: \Account.objectID) { account in
                        AccountCell(account: account, esi: account.oAuth2Token.map{ESI(token: $0)} ?? ESI())
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Accounts")
        }
    }
}

struct Accounts_Previews: PreviewProvider {
    static var previews: some View {
        Accounts().environment(\.managedObjectContext, AppDelegate.sharedDelegate.testingContainer.viewContext)
    }
}
