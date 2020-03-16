//
//  FittingCharacters.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.03.2020.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct FittingCharacters: View {
    var body: some View {
		List {
			FittingCharactersAccounts()
			FittingCharactersPredefined()
		}.listStyle(GroupedListStyle())
		.navigationBarTitle("Characters")
    }
}

struct FittingCharacters_Previews: PreviewProvider {
    static var previews: some View {
		_ = AppDelegate.sharedDelegate.testingAccount!
		return NavigationView {
			FittingCharacters()
		}.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
