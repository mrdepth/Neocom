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
    var completion: (Account) -> Void
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Account.characterName, ascending: true)])
    private var accounts: FetchedResults<Account>
    
    @State private var accountInfoCache = Cache<Account, AccountInfo>()
    @State private var characterInfoCache = Cache<Account, CharacterInfo>()
    
    private func accountInfo(for account: Account) -> AccountInfo {
        accountInfoCache[account, default: AccountInfo(esi: account.oAuth2Token.map{ESI(token: $0)} ?? ESI(),
                                                 characterID: account.characterID,
                                                 managedObjectContext: managedObjectContext)]
    }

    private func characterInfo(for account: Account) -> CharacterInfo {
        characterInfoCache[account, default: CharacterInfo(esi: account.oAuth2Token.map{ESI(token: $0)} ?? ESI(),
                                                           characterID: account.characterID,
                                                           characterImageSize: .size256)]
    }

    var body: some View {
        List {
            Button("Log In with EVE Online") {
                let url = OAuth2.authURL(clientID: Config.current.esi.clientID, callbackURL: Config.current.esi.callbackURL, scope: ESI.Scope.all, state: "esi")
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                controller.present(SFSafariViewController(url: url), animated: true, completion: nil)

//                _ = Account(token: oAuth2Token, context: self.managedObjectContext)
//                if self.managedObjectContext.hasChanges {
//                    try? self.managedObjectContext.save()
//                }
            }.frame(maxWidth: .infinity)
            Section {
                ForEach(accounts, id: \Account.objectID) { account in
                    Button(action: {self.completion(account)}) {
                        AccountCell(characterInfo: self.characterInfo(for: account), accountInfo: self.accountInfo(for: account)).contentShape(Rectangle())
                    }.buttonStyle(PlainButtonStyle())
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
            Accounts { _ in }
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(SharedState.testState())
    }
}
