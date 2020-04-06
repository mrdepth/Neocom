//
//  IncursionsItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct IncursionsItem: View {
    var body: some View {
        NavigationLink(destination: Incursions()) {
            Icon(Image("incursions"))
            Text("Incursions")
        }
    }
}

struct IncursionsItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                IncursionsItem()
            }.listStyle(GroupedListStyle())
        }
    }
}
