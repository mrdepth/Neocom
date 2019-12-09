//
//  MarketHistory.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct MarketHistory: View {
	
	private var grid: some View {
		ZStack {
			HStack(spacing: 0) {
				Divider()
				ForEach(0..<12) { _ in
					Spacer()
					Divider()
				}
			}
			VStack(spacing: 0) {
				Divider()
				ForEach(0..<5) { _ in
					Spacer()
					Divider()
				}
			}
		}
	}
	
    var body: some View {
		ZStack {
			grid.background(Color(.systemGroupedBackground))
			HStack(spacing: 0) {
				Group {
					Text("Jan").frame(maxWidth: .infinity)
					Text("Feb").frame(maxWidth: .infinity)
					Text("Mar").frame(maxWidth: .infinity)
				}
				Group {
					Text("Apr").frame(maxWidth: .infinity)
					Text("May").frame(maxWidth: .infinity)
					Text("Jun").frame(maxWidth: .infinity)
				}
				Group {
					Text("Jul").frame(maxWidth: .infinity)
					Text("Aug").frame(maxWidth: .infinity)
					Text("Sep").frame(maxWidth: .infinity)
				}
				Group {
					Text("Oct").frame(maxWidth: .infinity)
					Text("Nov").frame(maxWidth: .infinity)
					Text("Dec").frame(maxWidth: .infinity)
				}
			}.lineLimit(1).font(.caption)
		}.aspectRatio(13.0 / 6.0, contentMode: .fit)
			
			.padding()
    }
}

struct MarketHistory_Previews: PreviewProvider {
    static var previews: some View {
		let data = NSDataAsset(name: "dominixMarket")!.data
		let history = try! ESI.jsonDecoder.decode([ESI.Markets.RegionID.History.Success].self, from: data)
        return MarketHistory()
    }
}
