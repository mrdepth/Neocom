//
//  TypeInfoMarketHistoryCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/11/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct TypeInfoMarketHistoryCell: View {
	var type: SDEInvType
	
    @Environment(\.esi) var esi
//	@UserDefault(key: .marketRegionID)
	@ObservedObject private var regionID = UserDefault(wrappedValue: SDERegionID.default.rawValue,
													   key: .marketRegionID)
//	private var regionID: Int = SDERegionID.default.rawValue

	//    @ObservedObject var history: Lazy<MarketHistoryData> = Lazy()

//	var history: MarketHistoryData.History
    
    var body: some View {
		ObservedObjectView(MarketHistoryData(type: type, regionID: regionID.wrappedValue, esi: esi)) { history in
			NavigationLink(destination: TypeMarketOrders(type: self.type)) {
				MarketHistory(history: (history.result?.value ?? nil) ?? MarketHistoryData.History())
			}
		}
    }
}

struct TypeInfoMarketCell_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                TypeInfoMarketHistoryCell(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!)
            }.listStyle(GroupedListStyle())
        }
    }
}
