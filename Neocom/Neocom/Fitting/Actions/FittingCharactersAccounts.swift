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
    var onSelect: (URL, DGMSkillLevels) -> Void
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Account.characterName, ascending: true)])
    private var accounts: FetchedResults<Account>

    var body: some View {
		Section(header: Text("ACCOUNTS")) {
			ForEach(accounts, id: \.objectID) { account in
                FittingCharacterCell(account, onSelect: self.onSelect)
			}
		}
    }
}

struct FittingCharactersAccounts_Previews: PreviewProvider {
    static var previews: some View {
		_ = AppDelegate.sharedDelegate.testingAccount!
		return List {
			FittingCharactersAccounts {_, _ in}
		}.listStyle(GroupedListStyle())
		.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
