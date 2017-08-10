//
//  NCRangeFormatter.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

class NCRangeFormatter: Formatter {
	let unit: NCUnitFormatter.Unit
	let style: NCUnitFormatter.Style
	let useSIPrefix: Bool?
	private lazy var formatter1: NCUnitFormatter = {
		return NCUnitFormatter(unit: .none, style: self.style, useSIPrefix: self.useSIPrefix ?? self.unit.useSIPrefix)
	}()
	private lazy var formatter2: NCUnitFormatter = {
		return NCUnitFormatter(unit: self.unit, style: self.style, useSIPrefix: self.useSIPrefix ?? self.unit.useSIPrefix)
	}()

	init(unit: NCUnitFormatter.Unit = .none, style: NCUnitFormatter.Style = .full, useSIPrefix: Bool? = nil) {
		self.unit = unit
		self.style = style
		self.useSIPrefix = useSIPrefix
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		//self.unit = NCUnitFormatter.Unit(rawValue: aDecoder.decodeInteger(forKey: "unit")) ?? .none
		unit = .none
		style = NCUnitFormatter.Style(rawValue: aDecoder.decodeInteger(forKey: "style")) ?? .full
		useSIPrefix = aDecoder.containsValue(forKey: "useSIPrefix") ? aDecoder.decodeBool(forKey: "useSIPrefix") : nil
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		//aCoder.encode(unit.rawValue, forKey: "unit")
		aCoder.encode(style.rawValue, forKey: "style")
		aCoder.encode(useSIPrefix, forKey: "useSIPrefix")
	}

	
	@nonobjc func string(for value: Double, maximum: Double) -> String {
		return "\(formatter1.string(for: value)!)/\(formatter2.string(for: maximum)!)"
	}

	@nonobjc func string(for value: Float, maximum: Float) -> String {
		return "\(formatter1.string(for: value)!)/\(formatter2.string(for: maximum)!)"
	}

	@nonobjc func string(for value: Int, maximum: Int) -> String {
		return "\(formatter1.string(for: value)!)/\(formatter2.string(for: maximum)!)"
	}

	override func string(for obj: Any?) -> String? {
		guard let (value, maximum) = obj as? (Double, Double) else {return nil}
		return string(for: value, maximum: maximum)
	}

}
