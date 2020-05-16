//
//  DatabaseItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct DatabaseItem: View {
    @ObservedObject private var storage = Storage.sharedStorage

    var body: some View {
        NavigationLink(destination: TypeCategories()) {
            Icon(Image("items"))
            Text("Database")
        }.id(storage.currentLanguagID)
    }
}

struct DatabaseItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                DatabaseItem()
            }.listStyle(GroupedListStyle())
        }
    }
}
