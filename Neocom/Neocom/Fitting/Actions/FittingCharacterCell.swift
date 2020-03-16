//
//  FittingCharacterCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.03.2020.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct FittingCharacterCell: View {
	var account: Account?
	var level: Int?
	init(_ account: Account) {
		self.account = account
	}

	init(_ level: Int) {
		self.level = level
	}

    var body: some View {
		Group {
			if account != nil {
				FittingCharacterAccountCell(account: account!)
			}
			else if level != nil {
				FittingCharacterPredefinedCell(level: level!)
			}
		}
    }
}

fileprivate struct FittingCharacterAccountCell: View {
	var account: Account
	var body: some View {
		HStack {
			Avatar(characterID: account.characterID, size: .size128).frame(width: 40, height: 40)
			Text(account.characterName ?? "")
		}
	}
}

fileprivate struct FittingCharacterPredefinedCell: View {
	var level: String
	
	init(level: Int) {
		self.level = level == 0 ? "0" : String(roman: level)
	}
	var body: some View {
		HStack {
			ZStack {
				Color(UIColor.systemGroupedBackground)
				Text(level).font(.title2).foregroundColor(Color(.placeholderText))
			}
			.clipShape(Circle())
			.shadow(radius: 2)
			.overlay(Circle().strokeBorder(Color(UIColor.tertiarySystemBackground), lineWidth: 2, antialiased: true))
			.frame(width: 40, height: 40)
			Text("All Skills ") + Text(level).fontWeight(.semibold)
		}
	}
}

struct FittingCharacterCell_Previews: PreviewProvider {
    static var previews: some View {
		List {
			FittingCharacterCell(AppDelegate.sharedDelegate.testingAccount!)
			FittingCharacterCell(1)
		}.listStyle(GroupedListStyle())
		.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
