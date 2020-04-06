//
//  MarketItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct MarketItem: View {
    var body: some View {
        NavigationLink(destination: TypeMarketGroup()) {
            Icon(Image("market"))
            Text("Market")
        }
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
