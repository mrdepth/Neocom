//
//  MarketHistoryData.swift
//  Neocom
//
//  Created by Artem Shimanski on 17.12.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import Alamofire

class MarketHistoryData: ObservableObject {
	
	struct History {
		var volume: UIBezierPath = UIBezierPath()
		var median: UIBezierPath = UIBezierPath()
		var donchian: UIBezierPath = UIBezierPath()
		var donchianVisibleRange: CGRect = .null
		var dateRange: ClosedRange<Date> = Date()...Date()
	}
	
	@Published var result: Result<History?, AFError>?

	private var subscription: AnyCancellable?
	
	init(type: SDEInvType, regionID: Int, esi: ESI) {
		subscription = esi.markets.regionID(regionID).history().get(typeID: Int(type.typeID)).map { history in
            History(history: history.value)
		}.asResult()
			.receive(on: RunLoop.main)
			.sink { [weak self] result in
				self?.result = result
		}
	}
	
}

extension MarketHistoryData.History {
	init?(history: [ESI.MarketHistoryItem]) {
        guard !history.isEmpty else {return nil}
        guard let date = history.last?.date.addingTimeInterval(-3600 * 24 * 365) else {return nil}
        guard let i = history.firstIndex(where: { $0.date > date }) else { return nil }
        
        let range = history.suffix(from: i).indices
        
        let visibleRange = { () -> ClosedRange<Double> in
            var h2 = 0 as Double
            var h = 0 as Double
            var l2 = 0 as Double
            var l = 0 as Double
            let n = Double(range.count)
            for i in range {
                let item = history[i]
                h += Double(item.highest) / n
                h2 += Double(item.highest * item.highest) / n
                l += Double(item.lowest) / n
                l2 += Double(item.lowest * item.lowest) / n
            }
            let avgl = l
            let avgh = h
            h *= h
            l *= l
            let devh = h < h2 ? sqrt(h2 - h) : 0
            let devl = l < l2 ? sqrt(l2 - l) : 0
            return (avgl - devl * 3)...(avgh + devh * 3)
        }()
        
        let volume = UIBezierPath()
        //            volume.move(to: CGPoint(x: 0, y: 0))
        
        let donchian = UIBezierPath()
        let avg = UIBezierPath()
        
        var x: CGFloat = 0
        var isFirst = true
        
        var v = 0...0 as ClosedRange<Int64>
        var p = 0...0 as ClosedRange<Double>
        let dateRange = history[range.first!].date...history[range.last!].date
        var prevT: TimeInterval?
        
        var lowest = Double.greatestFiniteMagnitude as Double
        var highest = 0 as Double
        
        for i in range {
            let item = history[i]
            if visibleRange.contains(Double(item.lowest)) {
                lowest = min(lowest, Double(item.lowest))
            }
            if visibleRange.contains(Double(item.highest)) {
                highest = max(highest, Double(item.highest))
            }
            
            let t = item.date.timeIntervalSinceReferenceDate
            x = CGFloat(item.date.timeIntervalSinceReferenceDate)
            let lowest = history[max(i - 4, 0)...i].min {
                $0.lowest < $1.lowest
                }!
            let highest = history[max(i - 4, 0)...i].max {
                $0.highest < $1.highest
                }!
            if isFirst {
                avg.move(to: CGPoint(x: x, y: CGFloat(item.average)))
                isFirst = false
            }
            else {
                avg.addLine(to: CGPoint(x: x, y: CGFloat(item.average)))
            }
            if let prevT = prevT {
                volume.append(UIBezierPath(rect: CGRect(x: CGFloat(prevT), y: 0, width: CGFloat(t - prevT), height: CGFloat(item.volume))))
                donchian.append(UIBezierPath(rect: CGRect(x: CGFloat(prevT), y: CGFloat(lowest.lowest), width: CGFloat(t - prevT), height: abs(CGFloat(highest.highest - lowest.lowest)))))
            }
            prevT = t
            
            v = min(v.lowerBound, item.volume)...max(v.upperBound, item.volume)
            p = min(p.lowerBound, Double(lowest.lowest))...max(p.upperBound, Double(highest.highest))
        }
        
        var donchianVisibleRange = donchian.bounds
        if lowest < highest {
            donchianVisibleRange.origin.y = CGFloat(lowest)
            donchianVisibleRange.size.height = CGFloat(highest - lowest)
        }
        
        self.volume = volume
        self.median = avg
        self.donchian = donchian
        self.donchianVisibleRange = donchianVisibleRange
        self.dateRange = dateRange
    }
}
