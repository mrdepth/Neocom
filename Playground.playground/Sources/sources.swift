//
//  NCMarketHistoryView.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

public class NCDatabaseTypeMarketRow {
	public let volume: UIBezierPath
	public let median: UIBezierPath
	public let donchian: UIBezierPath
	public let date: ClosedRange<Date>
	init(history: [ESMarketHistory], volume: UIBezierPath, median: UIBezierPath, donchian: UIBezierPath, date: ClosedRange<Date>) {
		self.volume = volume
		self.median = median
		self.donchian = donchian
		self.date = date
	}
}

public func marketHistory(history: [ESMarketHistory]) -> NCDatabaseTypeMarketRow? {
	guard history.count > 0 else {return nil}
	guard let date = history.last?.date.addingTimeInterval(-3600 * 24 * 365) else {return nil}
	guard let i = history.index(where: {
		$0.date > date
	}) else {
		return nil
	}
	
	let range = history.suffix(from: i).indices
	
	let volume = UIBezierPath()
	volume.move(to: CGPoint(x: 0, y: 0))
	
	let donchian = UIBezierPath()
	let avg = UIBezierPath()
	
	var x: CGFloat = 0
	var isFirst = true
	
	var v = 0...0 as ClosedRange<Int>
	var p = 0...0 as ClosedRange<Double>
	let d = history[range.first!].date...history[range.last!].date
	var prevT: TimeInterval?
	
	for i in range {
		let item = history[i]
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
		p = min(p.lowerBound, lowest.lowest)...max(p.upperBound, highest.highest)
	}
	
	donchian.close()
	
	return NCDatabaseTypeMarketRow(history: history, volume: volume, median: avg, donchian: donchian, date: d)
	
	/*var transform = CGAffineTransform.identity
	var rect = volume.bounds
	if rect.size.width > 0 && rect.size.height > 0 {
	transform = transform.scaledBy(x: 1, y: -1)
	transform = transform.translatedBy(x: 0, y: -bounds.size.height)
	transform = transform.scaledBy(x: bounds.size.width / rect.size.width, y: bounds.size.height / rect.size.height * 0.25)
	transform = transform.translatedBy(x: -rect.origin.x, y: -rect.origin.y)
	volume.apply(transform)
	}
	
	
	rect = donchian.bounds.union(avg.bounds)
	if rect.size.width > 0 && rect.size.height > 0 {
	transform = CGAffineTransform.identity
	transform = transform.scaledBy(x: 1, y: -1)
	transform = transform.translatedBy(x: 0, y: -bounds.size.height * 0.75)
	transform = transform.scaledBy(x: bounds.size.width / rect.size.width, y: bounds.size.height / rect.size.height * 0.75)
	transform = transform.translatedBy(x: -rect.origin.x, y: -rect.origin.y)
	donchian.apply(transform)
	avg.apply(transform)
	}
	
	UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
	UIBezierPath(rect: bounds).fill()
	UIColor.lightGray.setFill()
	donchian.fill()
	UIColor.blue.setFill()
	volume.fill()
	UIColor.orange.setStroke()
	avg.stroke()
	let image = UIGraphicsGetImageFromCurrentImageContext()
	UIGraphicsEndImageContext()
	if let image = image {
	return NCDatabaseTypeMarketRow(chartImage: image, history: history, volume: v, price: p, date: d)
	}
	else {
	return nil
	}*/
}


extension UIColor {
	
	public convenience init(number: UInt) {
		var n = number
		var abgr = [CGFloat]()
		
		for _ in 0...3 {
			let byte = n & 0xFF
			abgr.append(CGFloat(byte) / 255.0)
			n >>= 8
		}
		
		self.init(red: abgr[3], green: abgr[2], blue: abgr[1], alpha: abgr[0])
	}
}


public class NCUnitFormatter: Formatter {
	public enum Unit {
		case none
		case isk
		case skillPoints
	}
	
	public enum Style {
		case short
		case full
	}
	
	var unit: Unit = .none
	var style: Style = .full
	var useSIPrefix: Bool = false
	
	private static let numberFormatter1: NumberFormatter = {
		let numberFormatter = NumberFormatter()
		numberFormatter.positiveFormat = "#,##0.##"
		numberFormatter.groupingSeparator = " "
		numberFormatter.decimalSeparator = "."
		return numberFormatter
		
	}()
	
	private static let numberFormatter2: NumberFormatter = {
		let numberFormatter = NumberFormatter()
		numberFormatter.positiveFormat = "#,##0"
		numberFormatter.groupingSeparator = " "
		numberFormatter.decimalSeparator = "."
		return numberFormatter
		
	}()
	
	public class func localizedString(from number: Double, unit: Unit, style: Style, useSIPrefix: Bool = false) -> String {
		let unitAbbreviation: String
		
		switch (unit) {
		case .isk:
			unitAbbreviation = NSLocalizedString("ISK", comment: "")
			break;
		case .skillPoints:
			unitAbbreviation = NSLocalizedString("SP", comment: "")
			break;
		default:
			unitAbbreviation = ""
			break;
		}
		
		var value = number
		let suffix: String
		if (style == .short) {
			if (value >= 10_000_000_000_000) {
				suffix = NSLocalizedString("T", comment: "trillion")
				value /= 1_000_000_000.0
			}
			else if (value >= 10_000_000_000) {
				if (useSIPrefix) {
					suffix = NSLocalizedString("G", comment: "billion")
				}
				else {
					suffix = NSLocalizedString("B", comment: "billion")
				}
				value /= 1_000_000_000.0
			}
			else if (value >= 10_000_000) {
				suffix = NSLocalizedString("M", comment:"million")
				value /= 1_000_000.0
			}
			else if (value >= 10_000) {
				suffix = NSLocalizedString("k", comment: "thousand")
				value /= 1000.0
			}
			else {
				suffix = ""
			}
		}
		else {
			suffix = ""
		}
		
		var s = ""
		if value < 10.0 {
			s = numberFormatter1.string(from: NSNumber(value: value))!
		}
		else {
			s = numberFormatter2.string(from: NSNumber(value: value))!
		}
		if !suffix.isEmpty {
			s += suffix
		}
		if !unitAbbreviation.isEmpty {
			s += " \(unitAbbreviation)"
		}
		return s;
	}
	
	override public func string(for obj: Any?) -> String? {
		guard let obj = obj as? Double else {return nil}
		return NCUnitFormatter.localizedString(from: obj, unit: unit, style: style, useSIPrefix: true)
	}
	
}
