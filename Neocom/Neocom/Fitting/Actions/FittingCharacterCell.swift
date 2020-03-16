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
    
    init(_ account: Account, onSelect: @escaping (URL, DGMSkillLevels) -> Void) {
		self.account = account
        self.onSelect = onSelect
	}

	init(_ level: Int, onSelect: @escaping (URL, DGMSkillLevels) -> Void) {
		self.level = level
        self.onSelect = onSelect
	}

    var body: some View {
		Group {
			if account != nil {
                FittingCharacterAccountCell(account: account!, onSelect: onSelect)
			}
			else if level != nil {
                FittingCharacterPredefinedCell(level: level!, onSelect: onSelect)
			}
		}
    }
}

fileprivate struct FittingCharacterAccountCell: View {
	var account: Account
    var onSelect: (URL, DGMSkillLevels) -> Void
    @State private var skillLoadingPublisher: AnyPublisher<DGMSkillLevels, Error>?
    
    private func action() {
        guard skillLoadingPublisher == nil else {return}
        skillLoadingPublisher = DGMSkillLevels.fromAccount(account)
    }
    
    private var publisher: AnyPublisher<DGMSkillLevels, Never> {
        skillLoadingPublisher?.map{$0 as Optional}.replaceError(with: nil).compactMap{$0}.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
    }
    
	var body: some View {
        Button(action: action) {
            HStack {
                Avatar(characterID: account.characterID, size: .size128).frame(width: 40, height: 40)
                Text(account.characterName ?? "")
                Spacer()
            }.contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(skillLoadingPublisher == nil ? 1 : 0.5)
        .overlay(skillLoadingPublisher != nil ? ActivityIndicator(style: .medium) : nil)
        .onReceive(publisher) { skills in
            self.skillLoadingPublisher = nil
            guard let url = DGMCharacter.url(account: self.account) else {return}
            self.onSelect(url, skills)
        }
    }
}

fileprivate struct FittingCharacterPredefinedCell: View {
	private var levelString: String
    var level: Int
	var onSelect: (URL, DGMSkillLevels) -> Void
    
	init(level: Int, onSelect: @escaping (URL, DGMSkillLevels) -> Void) {
        self.level = level
		self.levelString = level == 0 ? "0" : String(roman: level)
        self.onSelect = onSelect
	}
    
    private func action() {
        onSelect(DGMCharacter.url(level: level), .level(level))
    }
    
	var body: some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Color(UIColor.systemGroupedBackground)
                    Text(levelString).font(.title2).foregroundColor(Color(.placeholderText))
                }
                .clipShape(Circle())
                .shadow(radius: 2)
                .overlay(Circle().strokeBorder(Color(UIColor.tertiarySystemBackground), lineWidth: 2, antialiased: true))
                .frame(width: 40, height: 40)
                Text("All Skills ") + Text(levelString).fontWeight(.semibold)
                Spacer()
            }.contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
	}
}

struct FittingCharacterCell_Previews: PreviewProvider {
    static var previews: some View {
		List {
            FittingCharacterCell(AppDelegate.sharedDelegate.testingAccount!) { _, _ in }
			FittingCharacterCell(1) { _, _ in }
		}.listStyle(GroupedListStyle())
		.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
