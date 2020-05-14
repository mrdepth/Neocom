//
//  WormholesItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct WormholesItem: View {
    var body: some View {
        NavigationLink(destination: Wormholes()) {
            Icon(Image("terminate"))
            Text("Wormholes")
        }
    }
}

struct WormholesItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                WormholesItem()
            }.listStyle(GroupedListStyle())
        }
    }
}
