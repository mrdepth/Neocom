//
//  TypeInfoMarketCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/11/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct TypeInfoMarketCell: View {
    var history: TypeInfoData.Row.MarketHistory
    
    var body: some View {
        NavigationLink(destination: Text("sdf")) {
            MarketHistory(history: history)
        }
    }
}

struct TypeInfoMarketCell_Previews: PreviewProvider {
    static var previews: some View {
        let data = NSDataAsset(name: "dominixMarket")!.data
        let history = try! ESI.jsonDecoder.decode([ESI.MarketHistoryItem].self, from: data)

        return NavigationView {
            List {
                TypeInfoMarketCell(history: TypeInfoData.Row.MarketHistory(history: history)!)
            }.listStyle(GroupedListStyle())
        }
    }
}
