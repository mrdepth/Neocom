//
//  FittingCharactersAccounts.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.03.2020.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct FittingCharactersAccounts: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Account.characterName, ascending: true)])
    var accounts: FetchedResults<Account>

    var body: some View {
		Section(header: Text("ACCOUNTS")) {
			ForEach(accounts, id: \.objectID) { account in
				FittingCharacterCell(account)
			}
		}
    }
}

struct FittingCharactersAccounts_Previews: PreviewProvider {
    static var previews: some View {
		_ = AppDelegate.sharedDelegate.testingAccount!
		return List {
			FittingCharactersAccounts()
		}.listStyle(GroupedListStyle())
		.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
