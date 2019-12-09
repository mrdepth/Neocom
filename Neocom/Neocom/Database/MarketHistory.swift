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
    var history: TypeInfoData.Row.MarketHistory
    
    private func grid(_ columns: Int, _ rows: Int) -> some View {
		ZStack {
			HStack(spacing: 0) {
				Divider()
				ForEach(0..<columns) { _ in
					Spacer()
					Divider()
				}
			}
			VStack(spacing: 0) {
				Divider()
				ForEach(0..<rows) { _ in
					Spacer()
					Divider()
				}
			}
		}
	}
    
    private var xTitles: some View {
        let from = Calendar(identifier: .gregorian).component(.month, from: history.dateRange.lowerBound) - 1
//        let months = [Text("Jan"), Text("Feb"), Text("Mar"), Text("Apr"), Text("May"), Text("Jun"), Text("Jul"), Text("Aug"), Text("Sep"), Text("Oct"), Text("Nov"), Text("Dec")]
        
        return HStack(spacing: 0) {
            ForEach(from..<from + 12) { i in
                Text(Self.months[i % 12]).frame(maxWidth: .infinity)
            }
        }.lineLimit(1).font(.caption)
    }
    
    private static let months: [String] = [NSLocalizedString("JAN", comment: ""), NSLocalizedString("FEB", comment: ""), NSLocalizedString("MAR", comment: ""), NSLocalizedString("APR", comment: ""), NSLocalizedString("MAY", comment: ""), NSLocalizedString("JUN", comment: ""), NSLocalizedString("JUL", comment: ""), NSLocalizedString("AUG", comment: ""), NSLocalizedString("SEP", comment: ""), NSLocalizedString("OCT", comment: ""), NSLocalizedString("NOV", comment: ""), NSLocalizedString("DEC", comment: "")]
    
	
    var body: some View {
        let volumeBounds = self.history.volume.bounds
        
        return HStack {

                VStack(spacing: 0) {
                    Text("3000")
                    Text("2000")//.frame(maxHeight: .infinity)
                    Text("1000")//.frame(maxHeight: .infinity)
                    Text("0")//.frame(maxHeight: .infinity)
                }.font(.footnote)

            VStack(spacing: 2) {
                xTitles
                GeometryReader { geometry in
                    Path(self.history.volume.cgPath)
                        .transform(CGAffineTransform(scale: geometry.size / volumeBounds.size).translatedBy(-volumeBounds.origin))
                        .fill(Color.gray).scaleEffect(x: 1, y: -1, anchor: .center)
                        .overlay(self.grid(12, 4))
                        .background(Color(.systemGroupedBackground))
                }.aspectRatio(12.0 / 4, contentMode: .fit)
                
                GeometryReader { geometry in
                    Path(self.history.volume.cgPath)
                        .transform(CGAffineTransform(scale: geometry.size / volumeBounds.size).translatedBy(-volumeBounds.origin))
                        .fill(Color.gray).scaleEffect(x: 1, y: -1, anchor: .center)
                        .overlay(self.grid(12, 2))
                        .background(Color(.systemGroupedBackground))
                }.aspectRatio(12.0 / 2, contentMode: .fit)
            }
        }
        .padding()
    }
}

struct MarketHistory_Previews: PreviewProvider {
    static var previews: some View {
		let data = NSDataAsset(name: "dominixMarket")!.data
        let history = try! ESI.jsonDecoder.decode([ESI.MarketHistoryItem].self, from: data)
        return MarketHistory(history: TypeInfoData.Row.MarketHistory(history: history)!)
    }
}
