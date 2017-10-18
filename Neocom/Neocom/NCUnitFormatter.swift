//
//  NCUnitFormatter.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

class NCUnitFormatter: Formatter {
	enum Unit {
		case none
		case isk
		case skillPoints
		case gigaJoule
		case gigaJoulePerSecond
		case megaWatts
		case teraflops
		case kilogram
		case meter
		case millimeter
		case megaBitsPerSecond
		case cubicMeter
		case meterPerSecond
		case auPerSecond
		case hpPerSecond
		case custom(String, Bool)
		
		var useSIPrefix: Bool {
			switch self {
			case .isk, .skillPoints, .meter, .millimeter, .meterPerSecond, .auPerSecond, .hpPerSecond:
				return false
			case .gigaJoule, .gigaJoulePerSecond, .megaWatts, .teraflops, .kilogram, .megaBitsPerSecond, .cubicMeter:
				return true
			case let .custom(_, bool):
				return bool
			default:
				return false
			}
		}
		
		var abbreviation: String {
			switch (self) {
			case .isk:
				return NSLocalizedString("ISK", comment: "isk")
			case .skillPoints:
				return NSLocalizedString("SP", comment: "skillPoints")
			case .gigaJoule:
				return NSLocalizedString("GJ", comment: "gigaJoule")
			case .gigaJoulePerSecond:
				return NSLocalizedString("GJ/s", comment: "gigaJoulePerSecond")
			case .megaWatts:
				return NSLocalizedString("MW", comment: "megaWatts")
			case .teraflops:
				return NSLocalizedString("tf", comment: "teraflops")
			case .kilogram:
				return NSLocalizedString("kg", comment: "kilogram")
			case .meter:
				return NSLocalizedString("m", comment: "meter")
			case .millimeter:
				return NSLocalizedString("mm", comment: "millimeter")
			case .megaBitsPerSecond:
				return NSLocalizedString("Mbit/s", comment: "megaBitsPerSecond")
			case .cubicMeter:
				return NSLocalizedString("m³", comment: "cubicMeter")
			case .meterPerSecond:
				return NSLocalizedString("m/s", comment: "meterPerSecond")
			case .auPerSecond:
				return NSLocalizedString("AU/s", comment: "auPerSecond")
			case .hpPerSecond:
				return NSLocalizedString("HP/s", comment: "hpPerSecond")
			case let .custom(string, _):
				return string

			default:
				return ""
			}
		}
	}
	
	enum Style: Int {
		case short
		case full
	}
	
	let unit: Unit
	let style: Style
	let useSIPrefix: Bool?
	
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
	
	init(unit: Unit = .none, style: Style = .full, useSIPrefix: Bool? = nil) {
		self.unit = unit
		self.style = style
		self.useSIPrefix = useSIPrefix
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		//self.unit = Unit(rawValue: aDecoder.decodeInteger(forKey: "unit")) ?? .none
		self.unit = .none
		self.style = Style(rawValue: aDecoder.decodeInteger(forKey: "style")) ?? .full
		useSIPrefix = aDecoder.containsValue(forKey: "useSIPrefix") ? aDecoder.decodeBool(forKey: "useSIPrefix") : nil
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		//aCoder.encode(unit.rawValue, forKey: "unit")
		aCoder.encode(style.rawValue, forKey: "style")
		aCoder.encode(useSIPrefix, forKey: "useSIPrefix")
	}
	
	class func localizedString(from number: Int32, unit: Unit, style: Style, useSIPrefix: Bool? = nil) -> String {
		return localizedString(from: Double(number), unit: unit, style: style)
	}


	class func localizedString(from number: Int, unit: Unit, style: Style, useSIPrefix: Bool? = nil) -> String {
		return localizedString(from: Double(number), unit: unit, style: style)
	}

	class func localizedString(from number: Int64, unit: Unit, style: Style, useSIPrefix: Bool? = nil) -> String {
		return localizedString(from: Double(number), unit: unit, style: style)
	}

	class func localizedString(from number: Float, unit: Unit, style: Style, useSIPrefix: Bool? = nil) -> String {
		return localizedString(from: Double(number), unit: unit, style: style)
	}

	class func localizedString(from number: Double, unit: Unit, style: Style, useSIPrefix: Bool? = nil) -> String {
		let unitAbbreviation: String = unit.abbreviation
		let useSIPrefix = useSIPrefix ?? unit.useSIPrefix
		
		let sign = number < 0 ? -1.0 : 1.0
		var value = abs(number)
		var suffix: String
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
			s = numberFormatter1.string(from: NSNumber(value: value * sign))!
		}
		else {
			s = numberFormatter2.string(from: NSNumber(value: value * sign))!
		}
		if !unitAbbreviation.isEmpty {
			if useSIPrefix {
				suffix = " \(suffix)\(unitAbbreviation)"
			}
			else {
				suffix = "\(suffix) \(unitAbbreviation)"
			}
		}
		s += suffix
		return s;
	}

	override func string(for obj: Any?) -> String? {
		switch obj {
		case let obj as Double:
			return NCUnitFormatter.localizedString(from: obj, unit: unit, style: style, useSIPrefix: useSIPrefix)
		case let obj as Float:
			return NCUnitFormatter.localizedString(from: obj, unit: unit, style: style, useSIPrefix: useSIPrefix)
		case let obj as Int:
			return NCUnitFormatter.localizedString(from: obj, unit: unit, style: style, useSIPrefix: useSIPrefix)
		case let obj as Int32:
			return NCUnitFormatter.localizedString(from: obj, unit: unit, style: style, useSIPrefix: useSIPrefix)
		default:
			return nil
		}
	}

}
