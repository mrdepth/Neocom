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
	@State private var height: CGFloat = 24
    
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
        
        let titles = (from..<from + 12).map{Self.months[$0 % 12]}
        
        let s = NSAttributedString(string: titles.joined(), attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
        
        func fontScale(_ string: NSAttributedString, _ geometry: GeometryProxy) -> CGFloat {
            let context = NSStringDrawingContext()
            context.minimumScaleFactor = 0.1

            let rect = string.boundingRect(with: CGSize(width: geometry.size.width - 4 * CGFloat(titles.count), height: geometry.size.height), options: [.usesLineFragmentOrigin], context: context)
            return context.actualScaleFactor
        }
        
        return GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(from..<from + 12) { i in
                    Text(Self.months[i % 12]).frame(maxWidth: .infinity)//.padding(2)
                }
            }
//            .font(.system(.caption, design: .monospaced))
            .font(.system(size: UIFont.preferredFont(forTextStyle: .caption1).pointSize * fontScale(s, geometry), weight: .regular, design: .default))
//            .minimumScaleFactor(0.5)
        }
//		.lineLimit(1)
    }
	
	private func volume(_ geometry: GeometryProxy) -> some View {
		let volumeBounds = self.history.volume.bounds
		return Path(self.history.volume.cgPath)
			.transform(CGAffineTransform(scale: geometry.size / volumeBounds.size).translatedBy(-volumeBounds.origin))
			.fill(Color.gray).scaleEffect(x: 1, y: -1, anchor: .center)
//			.overlay(self.grid(12, 2))
//			.background(Color(.systemGroupedBackground))
	}
    
    private var volumeTitles: some View {
        let max = history.volume.bounds.maxY
        return VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 20)
            ForEach(0..<2) {_ in Spacer(minLength: 0).frame(maxHeight: .infinity)}
            Text(UnitFormatter.localizedString(from: Double(max), unit: .none, style: .short)).frame(maxHeight: .infinity, alignment: .bottom)
            Spacer(minLength: 0).frame(maxHeight: .infinity)
            Text("0").frame(maxHeight: .infinity, alignment: .bottom)
        }.font(.caption)
    }
    
//    private var priceTitles: some View {
//        let max = history.donchianVisibleRange.maxY
//    }
    
    private static let months: [String] = [NSLocalizedString("JAN", comment: ""), NSLocalizedString("FEB", comment: ""), NSLocalizedString("MAR", comment: ""), NSLocalizedString("APR", comment: ""), NSLocalizedString("MAY", comment: ""), NSLocalizedString("JUN", comment: ""), NSLocalizedString("JUL", comment: ""), NSLocalizedString("AUG", comment: ""), NSLocalizedString("SEP", comment: ""), NSLocalizedString("OCT", comment: ""), NSLocalizedString("NOV", comment: ""), NSLocalizedString("DEC", comment: "")]
    
	
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {

			VStack(spacing: 0) {
                Spacer().frame(height: 20)
                VStack(alignment: .trailing, spacing: 0) {
//                    Text("3 000k").frame(maxHeight: .infinity, alignment: .bottom)
                    Text("3 000k").frame(maxHeight: .infinity, alignment: .bottom)
                    Text("2000").frame(maxHeight: .infinity, alignment: .bottom)
                    Text("2000").frame(maxHeight: .infinity, alignment: .bottom)
                    Text("2000").frame(maxHeight: .infinity, alignment: .bottom)
                    Text("1000").frame(maxHeight: .infinity, alignment: .bottom)
					Text("0").frame(maxHeight: .infinity, alignment: .bottom)
                    }.font(.caption).frame(height: height)//.minimumScaleFactor(0.5)
            }

            VStack(spacing: 0) {
                xTitles.layoutPriority(1).frame(height: 20)
                GeometryReader { geometry in
					ZStack {
						self.volume(geometry)
						self.grid(12, 6)
					}.anchorPreference(key: SizePreferenceKey.self, value: Anchor<CGRect>.Source.bounds) { [geometry[$0].size] }
                }.aspectRatio(12.0 / 6, contentMode: .fit)
					.background(Color(.systemGroupedBackground))
					.onPreferenceChange(SizePreferenceKey.self) {
						self.height = $0.first?.height ?? 24
				}
            }
            volumeTitles.frame(height: height)
        }
        .padding().lineLimit(1)
    }
}

struct MarketHistory_Previews: PreviewProvider {
    static var previews: some View {
		let data = NSDataAsset(name: "dominixMarket")!.data
        let history = try! ESI.jsonDecoder.decode([ESI.MarketHistoryItem].self, from: data)
        return MarketHistory(history: TypeInfoData.Row.MarketHistory(history: history)!)
    }
}
