//
//  ContactPicker.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/2/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine
import EVEAPI

struct ContactPicker: View {
    var onSelect: (Contact) -> Void
    
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    func search(_ string: String) -> AnyPublisher<[Contact]?, Never> {
        let s = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.symbols))
        guard s.count > 3 else {return Just(nil).eraseToAnyPublisher()}
        return Contact.searchContacts(containing: s, esi: sharedState.esi, options: [.universe], managedObjectContext: managedObjectContext)
            .map{$0 as Optional}
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    
    var body: some View {
        SearchView(initialValue: nil, predicate: "", search: search) { searchResults in
            ContactsSearchResults(contacts: searchResults ?? []) { (contact) in
                contact.lastUse = Date()
                self.onSelect(contact)
            }
            .overlay(searchResults?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        }.navigationBarTitle("Pilots")
    }
}

#if DEBUG
struct ContactPicker_Previews: PreviewProvider {
    static var previews: some View {
        ContactPicker() { _ in}
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environmentObject(SharedState.testState())
    }
}
#endif
