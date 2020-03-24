//
//  FittingCharacterCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.03.2020.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Combine

struct FittingCharacterCell: View {
	var account: Account?
	var level: Int?
    var onSelect: (URL, DGMSkillLevels) -> Void
    
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    
    init(_ account: Account, onSelect: @escaping (URL, DGMSkillLevels) -> Void) {
		self.account = account
        self.onSelect = onSelect
	}

	init(_ level: Int, onSelect: @escaping (URL, DGMSkillLevels) -> Void) {
		self.level = level
        self.onSelect = onSelect
	}
    
    @State private var skillLoadingPublisher: AnyPublisher<DGMSkillLevels, Error>?
    
    private func accountAction() {
        guard let account = account, skillLoadingPublisher == nil else {return}
        skillLoadingPublisher = DGMSkillLevels.fromAccount(account, managedObjectContext: backgroundManagedObjectContext)
    }
    
    private func predefinedAction() {
        guard let level = level else {return}
        onSelect(DGMCharacter.url(level: level), .level(level))
    }
    
    private var publisher: AnyPublisher<DGMSkillLevels, Never> {
        skillLoadingPublisher?.map{$0 as Optional}.replaceError(with: nil).compactMap{$0}.receive(on: RunLoop.main).eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
    }

    
    var body: some View {
		Group {
			if account != nil {
                Button(action: accountAction) {
                    FittingCharacterAccountCell(account: account!).contentShape(Rectangle())
                        .opacity(skillLoadingPublisher == nil ? 1 : 0.5)
                        .overlay(skillLoadingPublisher != nil ? ActivityIndicator(style: .medium) : nil)
                }.buttonStyle(PlainButtonStyle())
			}
			else if level != nil {
                Button(action: predefinedAction) {
                    FittingCharacterLevelCell(level: level!).contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
			}
		}.onReceive(publisher) { skills in
            self.skillLoadingPublisher = nil
            guard let url = DGMCharacter.url(account: self.account!) else {return}
            self.onSelect(url, skills)
        }
    }
}

struct FittingCharacterAccountCell: View {
	var account: Account
    
	var body: some View {
        HStack {
            Avatar(characterID: account.characterID, size: .size128).frame(width: 40, height: 40)
            Text(account.characterName ?? "")
            Spacer()
        }
    }
}

struct LevelAvatar: View {
    var level: Int
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
            Text(level == 0 ? "0" : String(roman: level))
//                .font(.title2)
                .foregroundColor(Color(.placeholderText))
        }
        .clipShape(Circle())
        .shadow(radius: 2)
        .overlay(Circle().strokeBorder(Color(UIColor.tertiarySystemBackground), lineWidth: 2, antialiased: true))
    }
}

struct FittingCharacterLevelCell: View {
    var level: Int
    
	var body: some View {
        HStack {
            LevelAvatar(level: level).font(.title2)
                .frame(width: 40, height: 40)
            Text("All Skills ") + Text(level == 0 ? "0" : String(roman: level)).fontWeight(.semibold)
            Spacer()
        }
	}
}

struct FittingCharacterCell_Previews: PreviewProvider {
    static var previews: some View {
		List {
            FittingCharacterCell(AppDelegate.sharedDelegate.testingAccount!) { _, _ in }
			FittingCharacterCell(1) { _, _ in }
		}.listStyle(GroupedListStyle())
		.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
    }
}
