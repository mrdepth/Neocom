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
		case None
		case ISK
		case SkillPoints
	}
	
	enum Style {
		case Short
		case Full
	}
	
	var unit: Unit = .None
	var style: Style = .Full
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

	class func localizedString(from number: Double, unit: Unit, style: Style, useSIPrefix: Bool = false) -> String {
		let unitAbbreviation: String
		
		switch (unit) {
		case .ISK:
			unitAbbreviation = NSLocalizedString("ISK", comment: "")
			break;
		case .SkillPoints:
			unitAbbreviation = NSLocalizedString("SP", comment: "")
			break;
		default:
			unitAbbreviation = ""
			break;
		}
		
		var value = number
		let suffix: String
		if (style == Style.Short) {
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

	override func string(for obj: Any?) -> String? {
		guard let obj = obj as? Double else {return nil}
		return NCUnitFormatter.localizedString(from: obj, unit: unit, style: style, useSIPrefix: true)
	}

}
