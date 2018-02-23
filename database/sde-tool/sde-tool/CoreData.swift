//
//  CoreData.swift
//  sde-tool
//
//  Created by Artem Shimanski on 20.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

public typealias UIImage = Data

extension TypeAttribute {
	var value: Float? {
		if let value = valueFloat {
			return Float(value)
		}
		else if let value = valueInt {
			return Float(value)
		}
		else {
			return nil
		}
	}
}

extension NCDBEveIcon {
	
	convenience init?(_ iconID: (key: Int, value: IconID)) {
		guard let range = iconID.value.iconFile.range(of: "res:/ui/texture/icons") else {return nil}
		let path = iconID.value.iconFile.replacingCharacters(in: range, with: "")
		let url = URL(fileURLWithPath: CommandLine.input).appendingPathComponent(path)
		guard let data = try? Data(contentsOf: url) else {return nil}
		self.init(context: context)
		iconFile = url.deletingPathExtension().lastPathComponent
		image = NCDBEveIconImage(context: context)
		image?.image = data
	}
	
	class func icon(iconName: String) throws -> NCDBEveIcon? {
		if let eveIcon = nameIcons[iconName] {
			return eveIcon
		}
		else if let icon = try iconIDs.get().first(where: {$0.value.iconFile.hasSuffix("\(iconName).png")}),
			let eveIcon = try NCDBEveIcon.icon(iconID: icon.key) {
			return eveIcon
		}
		else {
			let url = URL(fileURLWithPath: CommandLine.input).appendingPathComponent("Icons/items/\(iconName).png")
			guard let data = try? Data(contentsOf: url) else {return nil}
			let icon = NCDBEveIcon(context: context)
			icon.image = NCDBEveIconImage(context: context)
			icon.image?.image = data
			nameIcons[iconName] = icon
			return icon
		}
	}
	
	class func icon(iconID: Int) throws -> NCDBEveIcon? {
		if let icon = eveIcons[iconID] {
			return icon
		}
		guard let icon = try iconIDs.get()[iconID] else {return nil}
		if let eveIcon = NCDBEveIcon((iconID, icon)) {
			eveIcons[iconID] = eveIcon
			return eveIcon
		}
		return nil
	}
	
	class func icon(typeID: Int) -> NCDBEveIcon? {
		let url = URL(fileURLWithPath: CommandLine.input).appendingPathComponent("Types/\(typeID)_64.png")
		guard let data = try? Data(contentsOf: url) else {return nil}
		let hash = data.hashValue
		if let icon = typeIcons[hash] {
			return icon
		}
		let icon = NCDBEveIcon(context: context)
		icon.image = NCDBEveIconImage(context: context)
		icon.image?.image = data
		typeIcons[hash] = icon
		return icon
	}

}


extension NCDBInvCategory {
	convenience init(_ category: (key: Int, value: CategoryID)) throws {
		self.init(context: context)
		categoryID = Int32(category.key)
		categoryName = category.value.name.en
		published = category.value.published
		if let iconID = category.value.iconID {
			try icon = NCDBEveIcon.icon(iconID: iconID)
		}
	}
}

extension NCDBInvGroup {
	convenience init(_ group: (key: Int, value: GroupID)) throws {
		self.init(context: context)
		groupID = Int32(group.key)
		groupName = group.value.name.en
		published = group.value.published
		try category = invCategories.get()[group.value.categoryID]
		if let iconID = group.value.iconID {
			try icon = NCDBEveIcon.icon(iconID: iconID)
		}
	}
}

extension NCDBInvType {
	convenience init(_ type: (key: Int, value: TypeID), typeIDs: Schema.TypeIDs) throws {
		self.init(context: context)
		typeID = Int32(type.key)
		typeName = (type.value.name.en ?? "").replacingEscapes()
		try group = invGroups.get()[type.value.groupID]
		basePrice = Float(type.value.basePrice ?? 0)
		capacity = Float(type.value.capacity ?? 0)
		mass = Float(type.value.mass ?? 0)
		radius = Float(type.value.radius ?? 0)
		volume = Float(type.value.volume ?? 0)
		published = type.value.published
		portionSize = Int32(type.value.portionSize)
		try metaLevel = Int16(typeAttributes.get()[type.key]?[NCDBDgmAttributeID.metaLevel.rawValue]?.value ?? 0)
		icon = .icon(typeID: type.key)
		if let raceID = type.value.raceID {
			try race = chrRaces.get()[raceID]!
		}
		if let marketGroupID = type.value.marketGroupID {
			try marketGroup = invMarketGroups.get()[marketGroupID]!
		}
		
		if published {
			try metaGroup = invMetaGroups.get()[metaTypes.get()[type.key]?.metaGroupID ?? defaultMetaGroupID]
		}
		else {
			metaGroup = unpublishedMetaGroup
		}
		
		try typeAttributes.get()[type.key]?.forEach { (attributeID, attribute) in
			let typeAttribute = NCDBDgmTypeAttribute(context: context)
			typeAttribute.type = self
			typeAttribute.value = attribute.value ?? 0
			try typeAttribute.attributeType = dgmAttributeTypes.get()[attribute.attributeID]!
		}

		
		func traitToString(_ trait: TypeID.Traits.Bonus) throws -> String? {
			guard let bonusText = trait.bonusText?.en else {
				return nil
			}
			if let bonus = trait.bonus {
				var int: Double = 0
				let value: String
				if modf(bonus, &int) != 0 {
					value = "\(bonus)"
				}
				else {
					value = "\(Int(int))"
				}
				if let unitID = trait.unitID {
					let unit = try eveUnits.get()[unitID]!
					return "<color=white><b>\(value)\(unit.displayName!)</b></color> \(bonusText)"
				}
				else {
					return "<color=white><b>\(value)</b></color> \(bonusText)"
				}
			}
			else {
				return "<color=white><b>-</b></color> \(bonusText)"
			}
		}
		
		let roleBonuses = try type.value.traits?.roleBonuses?.flatMap { try traitToString($0) }.joined(separator: "\n")
		let miscBonuses = try type.value.traits?.miscBonuses?.flatMap { try traitToString($0) }.joined(separator: "\n")
		let skillBonuses = try type.value.traits?.types?.map { (typeID, traits) -> String in
			let skill = typeIDs[typeID]!
			let title = "<a href=showinfo:\(typeID)>\(skill.name.en!)</a> bonuses (per skill level):"
			return "\(title)\n \(try traits.flatMap{try traitToString($0)}.joined(separator: "\n"))"
		}
		var traitGroups = [String]()
		if let s = roleBonuses, !s.isEmpty {
			traitGroups.append("<b>Role Bonus</b>:\n\(s)")
		}
		if let skillBonuses = skillBonuses {
			traitGroups.append(contentsOf: skillBonuses)
		}
		if let s = miscBonuses, !s.isEmpty {
			traitGroups.append("<b>Misc Bonuses</b>:\n\(s)")
		}
		
		var description = type.value.description?.en?.replacingEscapes() ?? ""
		if !traitGroups.isEmpty {
			description += "\n\n" + traitGroups.joined(separator: "\n\n")
		}
		if !description.isEmpty {
			typeDescription = NCDBTxtDescription(context: context)
			typeDescription?.text = NSAttributedString(html: description)
		}
		
	}
}

extension NCDBInvMetaGroup {
	convenience init(_ metaGroup: MetaGroup) {
		self.init(context: context)
		metaGroupID = Int32(metaGroup.metaGroupID)
		metaGroupName = metaGroup.metaGroupName
	}
}

extension NCDBInvMarketGroup {
	convenience init(_ marketGroup: MarketGroup) throws {
		self.init(context: context)
		marketGroupID = Int32(marketGroup.marketGroupID)
		marketGroupName = marketGroup.marketGroupName
		if let iconID = marketGroup.iconID {
			try icon = .icon(iconID: iconID)
		}
	}
}

extension NCDBEveUnit {
	convenience init(_ unit: Unit) {
		self.init(context: context)
		unitID = Int32(unit.unitID)
		displayName = unit.displayName
	}
}

extension NCDBDgmAttributeCategory {
	convenience init(_ attributeCategory: AttributeCategory) {
		self.init(context: context)
		categoryID = Int32(attributeCategory.categoryID)
		categoryName = attributeCategory.categoryName
	}
}

extension NCDBDgmAttributeType {
	convenience init(_ attributeType: AttributeType) throws {
		self.init(context: context)
		attributeID = Int32(attributeType.attributeID)
		attributeName = attributeType.attributeName
		displayName = attributeType.displayName
		published = attributeType.published
		if let categoryID = attributeType.categoryID {
			try attributeCategory = dgmAttributeCategories.get()[categoryID]
		}
		if let iconID = attributeType.iconID {
			try icon = .icon(iconID: iconID)
		}
		if let unitID = attributeType.unitID {
			try unit = eveUnits.get()[unitID]
		}
	}
}

extension NCDBChrRace {
	convenience init(_ race: Race) throws {
		self.init(context: context)
		raceID = Int32(race.raceID)
		raceName = race.raceName
		if let iconID = race.iconID {
			try icon = .icon(iconID: iconID)
		}
	}
}
