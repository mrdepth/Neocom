//
//  DatabaseItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct DatabaseItem: View {
    var body: some View {
        NavigationLink(destination: TypeCategories()) {
            Icon(Image("items"))
            Text("Database")
        }
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
