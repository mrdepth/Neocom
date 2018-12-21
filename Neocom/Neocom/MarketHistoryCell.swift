//
//  MarketHistoryCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import TreeController

class MarketHistoryCell: RowCell {
	@IBOutlet weak var marketHistoryView: MarketHistoryView!
}

extension Prototype {
	enum MarketHistoryCell {
		static let `default` = Prototype(nib: UINib(nibName: "MarketHistoryCell", bundle: nil), reuseIdentifier: "MarketHistoryCell")
	}
}

extension Tree.Content {
	struct MarketHistory: Hashable {
		var prototype: Prototype? = Prototype.MarketHistoryCell.default
		var volume: UIBezierPath?
		var median: UIBezierPath?
		var donchian: UIBezierPath?
		var donchianVisibleRange: CGRect?
		var date: ClosedRange<Date>?
		
		init(history: [ESI.Market.History]) {
			guard history.count > 0 else {return}
			guard let date = history.last?.date.addingTimeInterval(-3600 * 24 * 365) else {return}
			guard let i = history.index(where: {
				$0.date > date
			}) else {
				return
			}
			
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
//			volume.move(to: CGPoint(x: 0, y: 0))
			
			let donchian = UIBezierPath()
			let avg = UIBezierPath()
			
			var x: CGFloat = 0
			var isFirst = true
			
			var v = 0...0 as ClosedRange<Int64>
			var p = 0...0 as ClosedRange<Double>
			let d = history[range.first!].date...history[range.last!].date
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
			self.date = d
		}
	}
}

extension Tree.Content.MarketHistory: CellConfigurable {
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? MarketHistoryCell else {return}
		cell.marketHistoryView.volume = volume
		cell.marketHistoryView.median = median
		cell.marketHistoryView.donchian = donchian
		cell.marketHistoryView.donchianVisibleRange = donchianVisibleRange
		cell.marketHistoryView.date = date

	}
}

