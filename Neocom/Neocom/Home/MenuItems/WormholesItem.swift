//
//  WormholesItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct WormholesItem: View {
    @EnvironmentObject private var storage: Storage
    
    var body: some View {
        NavigationLink(destination: Wormholes()) {
            Icon(Image("terminate"))
            Text("Wormholes")
        }.id(storage.currentLanguagID)
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
