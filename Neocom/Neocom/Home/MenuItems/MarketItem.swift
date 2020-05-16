//
//  MarketItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct MarketItem: View {
    @ObservedObject private var storage = Storage.sharedStorage
    
    var body: some View {
        NavigationLink(destination: TypeMarketGroup()) {
            Icon(Image("market"))
            Text("Market")
        }.id(storage.currentLanguagID)
    }
}

struct MarketItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                MarketItem()
            }.listStyle(GroupedListStyle())
        }
    }
}
