//
//  ContactsSearchResults.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/18/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine
import EVEAPI

struct ContactsSearchResults: View {
    var contacts: [Contact] = []
    var onSelect: (Contact) -> Void
    
    private func cell(_ contact: Contact) -> some View {
        Button(action: {self.onSelect(contact)}) {
            ContactCell(contact: contact)
        }.buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        var contacts = self.contacts
        let i = contacts.partition{$0.recipientType == .alliance}
        let j = contacts[..<i].partition{$0.recipientType == .corporation}
        let alliances = contacts[i...].sorted{($0.name ?? "") < ($1.name ?? "")}.prefix(100)
        let corporations = contacts[j..<i].sorted{($0.name ?? "") < ($1.name ?? "")}.prefix(100)
        let characters = contacts[..<j].sorted{($0.name ?? "") < ($1.name ?? "")}.prefix(100)
        
        return List {
            if !characters.isEmpty {
                Section(header: Text("CHARACTERS")) {
                    ForEach(characters, id: \.objectID) { contact in
                        self.cell(contact)
                    }
                }
            }
            if !corporations.isEmpty {
                Section(header: Text("CORPORATIONS")) {
                    ForEach(corporations, id: \.objectID) { contact in
                        self.cell(contact)
                    }
                }
            }
            if !alliances.isEmpty {
                Section(header: Text("ALLIANCES")) {
                    ForEach(alliances, id: \.objectID) { contact in
                        self.cell(contact)
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
}

struct ContactsSearchResults_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return ContactsSearchResults(contacts: []) { _ in}
            .environment(\.esi, esi)
    }
}
