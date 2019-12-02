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
    
    @State var cache = Cache<Account, AccountInfo>()
    
    private func info(for account: Account) -> AccountInfo {
        cache[account, default: AccountInfo(esi: account.oAuth2Token.map{ESI(token: $0)} ?? ESI(),
                                                 characterID: account.characterID,
                                                 managedObjectContext: managedObjectContext,
                                                 characterImageSize: .size256)]
    }
    
    var body: some View {
        List {
            Button("Add new account") {
                _ = Account(token: oAuth2Token, context: self.managedObjectContext)
                if self.managedObjectContext.hasChanges {
                    try? self.managedObjectContext.save()
                }
            }.frame(maxWidth: .infinity)
            Section {
                ForEach(accounts, id: \Account.objectID) { account in
                    AccountCell(accountInfo: self.info(for: account))
                }.onDelete { (indices) in
                    withAnimation {
                        indices.forEach { i in
                            self.managedObjectContext.delete(self.accounts[i])
                        }
                        if self.managedObjectContext.hasChanges {
                            try? self.managedObjectContext.save()
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("Accounts")
        .navigationBarItems(trailing: EditButton())
    }
}

struct Accounts_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Accounts().environment(\.managedObjectContext, AppDelegate.sharedDelegate.testingContainer.viewContext)
        }
    }
}
