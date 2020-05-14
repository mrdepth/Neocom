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
	
    @EnvironmentObject private var sharedState: SharedState
	@ObservedObject private var regionID = UserDefault(wrappedValue: SDERegionID.default.rawValue,
													   key: .marketRegionID)
    
    var body: some View {
        ObservedObjectView(MarketHistoryData(type: type, regionID: Int(regionID.wrappedValue), esi: sharedState.esi)) { history in
			NavigationLink(destination: TypeMarketOrders(type: self.type)) {
				MarketHistory(history: (history.result?.value ?? nil) ?? MarketHistoryData.History())
			}
		}
    }
}

#if DEBUG
struct TypeInfoMarketCell_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                TypeInfoMarketHistoryCell(type: .dominix)
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
    }
}
#endif
