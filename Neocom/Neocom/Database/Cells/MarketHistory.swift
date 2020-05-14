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
	var history: MarketHistoryData.History
    static let volumeColor = Color.gray
    static let donchianColor = Color(.systemFill)
    static let medianColor = Color.skyBlue
    
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
        
        let titles = (from..<from + 12).map{Self.months[$0 % 12]}
        
        let s = NSAttributedString(string: titles.joined(), attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
        
        func fontScale(_ string: NSAttributedString, _ geometry: GeometryProxy) -> CGFloat {
            let context = NSStringDrawingContext()
            context.minimumScaleFactor = 0.1
            _ = string.boundingRect(with: CGSize(width: geometry.size.width - 6 * CGFloat(titles.count), height: geometry.size.height), options: [.usesLineFragmentOrigin], context: context)
            return context.actualScaleFactor
        }
        
        return GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(0..<12) { i in
                    Text(Self.months[(i + from) % 12]).frame(maxWidth: .infinity)//.padding(2)
                }
            }
            .font(.system(size: UIFont.preferredFont(forTextStyle: .caption1).pointSize * fontScale(s, geometry), weight: .regular, design: .default))
            .lineLimit(1)
        }
		
    }
	
    private var volume: some View {
		let volumeBounds = history.volume.bounds
        return GeometryReader { geometry in
			if !volumeBounds.isEmpty {
				Path(self.history.volume.cgPath)
					.transform(CGAffineTransform(scale: geometry.size / volumeBounds.size).translatedBy(-volumeBounds.origin))
					.fill(Self.volumeColor).scaleEffect(x: 1, y: -1, anchor: .center)
			}
        }
	}
    
    private var median: some View {
        let bounds = history.donchianVisibleRange
        return GeometryReader { geometry in
			if !bounds.isEmpty {
				Path(self.history.median.cgPath)
					.transform(CGAffineTransform(scale: geometry.size / bounds.size).translatedBy(-bounds.origin))
					.stroke(Self.medianColor).scaleEffect(x: 1, y: -1, anchor: .center)
			}
        }
    }
    
    private var donchian: some View {
        let bounds = history.donchianVisibleRange
        return GeometryReader { geometry in
			if !bounds.isEmpty {
				Path(self.history.donchian.cgPath)
					.transform(CGAffineTransform(scale: geometry.size / bounds.size).translatedBy(-bounds.origin))
					.fill(Self.donchianColor).scaleEffect(x: 1, y: -1, anchor: .center)
			}
        }
    }
    
    private var volumeTitles: some View {
		let bounds = history.volume.bounds
        let max = bounds.maxY
        let values = stride(from: 0, through: max, by: max / 2)
        return VStack(alignment: .leading, spacing: 0) {
			if !bounds.isEmpty {
				ForEach(0..<3) {_ in Spacer(minLength: 0).frame(maxHeight: .infinity)}
				ForEach(values.reversed(), id: \.self) {
					Text(UnitFormatter.localizedString(from: Int64($0), unit: .none, style: .short)).frame(maxHeight: .infinity, alignment: .bottom)
				}
			}
        }.font(.caption).frame(width: 30, alignment: .leading).minimumScaleFactor(0.5)
    }
    
    private var priceTitles: some View {
		let values =  {
			stride(from: self.history.donchianVisibleRange.minY, to: self.history.donchianVisibleRange.maxY, by: self.history.donchianVisibleRange.height / 4)
		}
        return VStack(alignment: .trailing, spacing: 0) {
			if !history.donchianVisibleRange.isEmpty {
				ForEach(values().reversed(), id: \.self) {
					Text(UnitFormatter.localizedString(from: Double($0), unit: .none, style: .short)).frame(maxHeight: .infinity, alignment: .bottom)
				}
				ForEach(0..<2) {_ in Spacer(minLength: 0).frame(maxHeight: .infinity)}
			}
        }.font(.caption).frame(width: 30, alignment: .trailing).minimumScaleFactor(0.5)
    }
    
    private static let months: [String] = [NSLocalizedString("JAN", comment: ""), NSLocalizedString("FEB", comment: ""), NSLocalizedString("MAR", comment: ""), NSLocalizedString("APR", comment: ""), NSLocalizedString("MAY", comment: ""), NSLocalizedString("JUN", comment: ""), NSLocalizedString("JUL", comment: ""), NSLocalizedString("AUG", comment: ""), NSLocalizedString("SEP", comment: ""), NSLocalizedString("OCT", comment: ""), NSLocalizedString("NOV", comment: ""), NSLocalizedString("DEC", comment: "")]
    
	
    var body: some View {
        VStack {
            HStack(alignment: .bottom, spacing: 4) {
                Spacer().frame(width: 30)
                VStack(spacing: 0) {
                    xTitles.layoutPriority(1).frame(height: 20)
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            ZStack {
                                self.donchian
                                self.median
                            }
                            self.volume.frame(height: geometry.size.height / 3)
                        }.overlay(self.grid(12, 6))
                            .clipped()
                    }.aspectRatio(12.0 / 6, contentMode: .fit)
                        .background(Color(.systemGroupedBackground))
                        .overlay(priceTitles.offset(x: -35), alignment: .leading)
                        .overlay(volumeTitles.offset(x: 35), alignment: .trailing)
                    
                }
                Spacer().frame(width: 30)
            }
            .lineLimit(1)
            HStack(spacing: 4) {
                Spacer()
                Rectangle().fill(Self.medianColor).frame(width: 4, height: 4)
                Text("MEDIAN")
                Spacer()
                Rectangle().fill(Self.volumeColor).frame(width: 6, height: 6)
                Text("VOLUME")
                Spacer()
                Rectangle().fill(Self.donchianColor).frame(width: 6, height: 6)//.background(Color(.systemGroupedBackground))
                Text("DONCHIAN CHANNEL")
                Spacer()
            }.font(.caption)
        }
        
    }
}

struct MarketHistory_Previews: PreviewProvider {
    static var previews: some View {
		let data = NSDataAsset(name: "dominixMarket")!.data
        let history = try! ESI.jsonDecoder.decode([ESI.MarketHistoryItem].self, from: data)
		return VStack {
			MarketHistory(history: MarketHistoryData.History(history: history)!).padding().background(Color(.systemBackground))//.colorScheme(.dark)
//			MarketHistory(history: MarketHistoryData.History()).padding().background(Color(.systemBackground))//.colorScheme(.dark)
		}
    }
}
