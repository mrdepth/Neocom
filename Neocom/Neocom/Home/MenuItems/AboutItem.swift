//
//  AboutItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/15/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct AboutItem: View {
    var body: some View {
        NavigationLink(destination: About()) {
            Icon(Image("info"))
            Text("About")
        }
    }
}

struct AboutItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                AboutItem()
            }.listStyle(GroupedListStyle())
        }
    }
}
