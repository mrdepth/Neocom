//
//  ContactsSearch.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/18/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine
import EVEAPI

struct ContactsSearch: View {
    var onSelect: (Contact) -> Void
    
    @Environment(\.esi) private var esi
    @Environment(\.managedObjectContext) private var managedObjectContext
    
//    func search(_ string: String) -> AnyPublisher<[Contact]?, Never> {
//        let s = string.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !s.isEmpty else {return Just(nil).eraseToAnyPublisher()}
//        return Contact.searchContacts(containing: s, esi: esi, options: [.universe], managedObjectContext: managedObjectContext)
//            .map{$0 as Optional}
//            .eraseToAnyPublisher()
//    }
    
    func search(_ string: NSAttributedString) -> AnyPublisher<[Contact]?, Never> {
        let s = string.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else {return Just(nil).eraseToAnyPublisher()}
        return Contact.searchContacts(containing: s, esi: esi, options: [.universe], managedObjectContext: managedObjectContext)
            .map{$0 as Optional}
            .eraseToAnyPublisher()
    }
    
//    @ObservedObject private var searchController: SearchController<[Contact]?, NSAttributedString>
    
    init(onSelect: @escaping (Contact) -> Void) {
        self.onSelect = onSelect
//        searchController = SearchController(initialValue: nil, predicate: NSAttributedString(), search)
    }
    
    var body: some View {
        ContactsSearchBody(search, onSelect: onSelect)
        .navigationBarTitle("Contacts")
    }
    
}

struct ContactsSearchBody: View {
    var onSelect: (Contact) -> Void
    
    @ObservedObject private var searchController: SearchController<[Contact]?, NSAttributedString>
    init(_ search: @escaping (NSAttributedString) -> AnyPublisher<[Contact]?, Never>, onSelect: @escaping (Contact) -> Void) {
        searchController = SearchController(initialValue: nil, predicate: NSAttributedString(string: "text"), search)
        self.onSelect = onSelect
    }
    
    var body: some View {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    TextView(text: self.$searchController.predicate,
                             typingAttributes: [.font: UIFont.preferredFont(forTextStyle: .body)],
                             style: .fixedLayoutWidth(geometry.size.width - 32 - 12))
//                        .padding(.horizontal, 16)
                    .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                    .foregroundColor(.secondary)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10.0)
                        .padding(.bottom, 8)

                    List {
                        if self.searchController.results != nil {
                            ContactsSearchResults(contacts: self.searchController.results!, onSelect: self.onSelect)
                        }
                    }.listStyle(GroupedListStyle())
                }
            }
        }
}

struct ContactsSearch_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return NavigationView {
            ContactsSearch() { _ in }
        }
            .environment(\.esi, esi)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
