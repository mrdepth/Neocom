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

struct ObjectID<T: NSManagedObject> {
	fileprivate var opaque: NSManagedObjectID
	init(_ object: T) {
		opaque = object.objectID
	}
	func object() throws -> T {
		return try NSManagedObjectContext.current.object(with: self)
	}
}

extension NSManagedObjectContext {
	static var current: NSManagedObjectContext! {
		get {
			return Thread.current.threadDictionary["managedObjectContext"] as! NSManagedObjectContext
		}
		set {
			Thread.current.threadDictionary["managedObjectContext"] = newValue
		}
	}
	
	func object<T>(with id: ObjectID<T>) throws -> T {
		return object(with: id.opaque) as! T
	}
}


//extension TypeAttribute {
//	var value: Double? {
//		if let value = valueFloat {
//			return value
//		}
//		else if let value = valueInt {
//			return Double(value)
//		}
//		else {
//			return nil
//		}
//	}
//}

extension NCDBEveIcon {
	static let lock = NSRecursiveLock()
	
	convenience init?(_ iconID: (key: Int, value: IconID)) {
		guard let range = iconID.value.iconFile.range(of: "res:/ui/texture/icons") else {return nil}
		let path = iconID.value.iconFile.replacingCharacters(in: range, with: "Icons/items")
		let url = URL(fileURLWithPath: CommandLine.input).appendingPathComponent(path)
		guard let data = try? Data(contentsOf: url) else {return nil}
		self.init(context: .current)
		iconFile = url.deletingPathExtension().lastPathComponent
		image = NCDBEveIconImage(context: .current)
		image?.image = data
	}
	
	class func icon(iconName: String) throws -> NCDBEveIcon? {
		lock.lock(); defer {lock.unlock()}
		if let eveIcon = nameIcons[iconName] {
			return try eveIcon.object()
		}
		else if let icon = try iconIDs.get().first(where: {$0.value.iconFile.hasSuffix("\(iconName).png")}),
			let eveIcon = try NCDBEveIcon.icon(iconID: icon.key) {
			return eveIcon
		}
		else {
			let url = URL(fileURLWithPath: CommandLine.input).appendingPathComponent("Icons/items/\(iconName).png")
			guard let data = try? Data(contentsOf: url) else {return nil}
			let icon = NCDBEveIcon(context: .current)
			icon.image = NCDBEveIconImage(context: .current)
			icon.iconFile = iconName
			icon.image?.image = data
//			try NSManagedObjectContext.current.save()
			nameIcons[iconName] = .init(icon)
			return icon
		}
	}
	
	class func icon(iconID: Int) throws -> NCDBEveIcon? {
		lock.lock(); defer {lock.unlock()}
		if let icon = eveIcons[iconID] {
			return try icon.object()
		}
		guard let icon = try iconIDs.get()[iconID] else {return nil}
		if let eveIcon = NCDBEveIcon((iconID, icon)) {
//			try NSManagedObjectContext.current.save()
			eveIcons[iconID] = .init(eveIcon)
			return eveIcon
		}
		return nil
	}
	
	class func icon(typeID: Int) throws -> NCDBEveIcon? {
		lock.lock(); defer {lock.unlock()}
		let url = URL(fileURLWithPath: CommandLine.input).appendingPathComponent("Types/\(typeID)_64.png")
		guard let data = try? Data(contentsOf: url) else {return nil}
		let hash = data.hashValue
		if let icon = typeIcons[hash] {
			return try icon.object()
		}
		let icon = NCDBEveIcon(context: .current)
		icon.image = NCDBEveIconImage(context: .current)
		icon.image?.image = data
//		try NSManagedObjectContext.current.save()
		typeIcons[hash] = .init(icon)
		return icon
	}

}


extension NCDBInvCategory {
	convenience init(_ category: (key: Int, value: CategoryID)) throws {
		self.init(context: .current)
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
		self.init(context: .current)
		groupID = Int32(group.key)
		groupName = group.value.name.en
		published = group.value.published
		try category = invCategories.get()[group.value.categoryID]?.object()
		if let iconID = group.value.iconID {
			try icon = NCDBEveIcon.icon(iconID: iconID)
		}
	}
}

extension NCDBInvType {
	convenience init(_ type: (key: Int, value: TypeID), typeIDs: Schema.TypeIDs) throws {
		self.init(context: .current)
		typeID = Int32(type.key)
		typeName = (type.value.name.en ?? "").replacingEscapes()
		try group = invGroups.get()[type.value.groupID]?.object()
		basePrice = type.value.basePrice ?? 0
		capacity = type.value.capacity ?? 0
		mass = type.value.mass ?? 0
		radius = type.value.radius ?? 0
		volume = type.value.volume ?? 0
		published = type.value.published
		portionSize = Int32(type.value.portionSize)
		try metaLevel = Int16(typeAttributes.get()[type.key]?[NCDBDgmAttributeID.metaLevel.rawValue]?.value ?? 0)
		icon = try .icon(typeID: type.key)
		if let raceID = type.value.raceID {
			try race = chrRaces.get()[raceID]!.object()
		}
		if let marketGroupID = type.value.marketGroupID {
			try marketGroup = invMarketGroups.get()[marketGroupID]!.object()
		}
		
		if published {
			try metaGroup = invMetaGroups.get()[metaTypes.get()[type.key]?.metaGroupID ?? defaultMetaGroupID]?.object()
		}
		else {
			try metaGroup = unpublishedMetaGroup.object()
		}
		
		try typeAttributes.get()[type.key]?.forEach { (attributeID, attribute) in
			let typeAttribute = NCDBDgmTypeAttribute(context: .current)
			typeAttribute.type = self
			typeAttribute.value = attribute.value ?? 0
			try typeAttribute.attributeType = dgmAttributeTypes.get()[attribute.attributeID]!.object()
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
					let unit = try eveUnits.get()[unitID]!.object()
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
			typeDescription = NCDBTxtDescription(context: .current)
			typeDescription?.text = NSAttributedString(html: description)
		}
		
		if group?.groupID == 988 {
			try wormhole = NCDBWhType(self)
		}
	}
}

extension NCDBInvMetaGroup {
	convenience init(_ metaGroup: MetaGroup) {
		self.init(context: .current)
		metaGroupID = Int32(metaGroup.metaGroupID)
		metaGroupName = metaGroup.metaGroupName
	}
}

extension NCDBInvMarketGroup {
	convenience init(_ marketGroup: MarketGroup) throws {
		self.init(context: .current)
		marketGroupID = Int32(marketGroup.marketGroupID)
		marketGroupName = marketGroup.marketGroupName
		if let iconID = marketGroup.iconID {
			try icon = .icon(iconID: iconID)
		}
	}
}

extension NCDBEveUnit {
	convenience init(_ unit: Unit) {
		self.init(context: .current)
		unitID = Int32(unit.unitID)
		displayName = unit.displayName
	}
}

extension NCDBDgmAttributeCategory {
	convenience init(_ attributeCategory: AttributeCategory) {
		self.init(context: .current)
		categoryID = Int32(attributeCategory.categoryID)
		categoryName = attributeCategory.categoryName
	}
}

extension NCDBDgmAttributeType {
	convenience init(_ attributeType: AttributeType) throws {
		self.init(context: .current)
		attributeID = Int32(attributeType.attributeID)
		attributeName = attributeType.attributeName
		displayName = attributeType.displayName
		published = attributeType.published
		if let categoryID = attributeType.categoryID {
			try attributeCategory = dgmAttributeCategories.get()[categoryID]?.object()
		}
		if let iconID = attributeType.iconID {
			try icon = .icon(iconID: iconID)
		}
		if let unitID = attributeType.unitID {
			try unit = eveUnits.get()[unitID]?.object()
		}
	}
}

extension NCDBDgmEffect {
	convenience init(_ effect: Effect) {
		self.init(context: .current)
		effectID = Int32(effect.effectID)
	}
}

extension NCDBChrRace {
	convenience init(_ race: Race) throws {
		self.init(context: .current)
		raceID = Int32(race.raceID)
		raceName = race.raceName
		if let iconID = race.iconID {
			try icon = .icon(iconID: iconID)
		}
	}
}

extension NCDBChrFaction {
	convenience init(_ faction: Faction) throws {
		self.init(context: .current)
		factionID = Int32(faction.factionID)
		factionName = faction.factionName
		if let iconID = faction.iconID {
			try icon = .icon(iconID: iconID)
		}
		race = try chrRaces.get()[faction.raceIDs]?.object()
	}
}

extension NCDBCertMasteryLevel {
	convenience init(level: Int, name: String, iconName: String) throws {
		self.init(context: .current)
		self.level = Int16(level)
		displayName = name
		icon = try .icon(iconName: iconName)
	}
}

extension NCDBCertCertificate {
	convenience init(_ certificate: (key: Int, value: Certificate)) throws {
		self.init(context: .current)
		certificateID = Int32(certificate.key)
		certificateName = certificate.value.name
		try group = invGroups.get()[certificate.value.groupID]!.object()
		certificateDescription = NCDBTxtDescription(context: .current)
		certificateDescription?.text = NSAttributedString(html: certificate.value.description.replacingEscapes())
		let types = try invTypes.get()
		
		let masteries = try certMasteryLevels.get().map { i -> NCDBCertMastery in
			let mastery = NCDBCertMastery(context: .current)
			try mastery.level = i.object()
			mastery.certificate = self
			return mastery
		}
		
		try certificate.value.skillTypes.forEach { (skillID, skill) in
			try [skill.basic, skill.standard, skill.improved, skill.advanced, skill.elite].enumerated().forEach {
				let skill = NCDBCertSkill(context: .current)
				try skill.type = types[skillID]!.object()
				skill.skillLevel = Int16($0.element)
				skill.mastery = masteries[$0.offset]
			}
		}
		if let recommendedFor = try certificate.value.recommendedFor?.flatMap ({try types[$0]?.object()}), !recommendedFor.isEmpty {
			self.types = Set(recommendedFor) as NSSet
		}
	}
}


extension NCDBMapRegion {
	convenience init(_ region: Region) throws {
		self.init(context: .current)
		regionID = Int32(region.regionID)
		regionName = try invNames.get()[region.regionID]!
		if let factionID = region.factionID {
			faction = try chrFactions.get()[factionID]!.object()
		}
	}
}

extension NCDBMapConstellation {
	convenience init(_ constellation: Constellation) throws {
		self.init(context: .current)
		constellationID = Int32(constellation.constellationID)
		constellationName = try invNames.get()[constellation.constellationID]!
		if let factionID = constellation.factionID {
			faction = try chrFactions.get()[factionID]!.object()
		}
	}
}

extension NCDBMapSolarSystem {
	convenience init(_ solarSystem: SolarSystem) throws {
		self.init(context: .current)
		solarSystemID = Int32(solarSystem.solarSystemID)
		solarSystemName = try invNames.get()[solarSystem.solarSystemID]!
		security = Float(solarSystem.security)
		if let factionID = solarSystem.factionID {
			faction = try chrFactions.get()[factionID]!.object()
		}
		
		try solarSystem.planets.forEach {
			try NCDBMapPlanet($0).solarSystem = self
		}
	}
}

extension NCDBMapPlanet {
	convenience init(_ planet: (Int, SolarSystem.Planet)) throws {
		self.init(context: .current)
		planetID = Int32(planet.0)
		try planetName = invNames.get()[planet.0]!
		try type = invTypes.get()[planet.1.typeID]!.object()
	}
}

extension NCDBStaStation {
	convenience init(_ station: Station) throws {
		self.init(context: .current)
		stationID = Int32(station.stationID)
		stationName = station.stationName
		security = Float(station.security)
		try stationType = invTypes.get()[station.stationTypeID]!.object()
		try solarSystem = mapSolarSystems.get()[station.solarSystemID]!.object()
	}
}

//extension NCDBMapDenormalize {
//	convenience init(station: (key: Int, value: SolarSystem.Planet.Station), solarSystem: SolarSystem) throws {
//		self.init(context: .current)
//		itemID = Int32(station.key)
//		try itemName = invNames.get()[station.key]!
//		security = Float(solarSystem.security)
//		try self.solarSystem = mapSolarSystems.get()[solarSystem.solarSystemID]!.object()
//		try type = invTypes.get()[station.value.typeID]!.object()
//
//	}
//}

extension NCDBRamActivity {
	convenience init(_ activity: Activity) throws {
		self.init(context: .current)
		activityID = Int32(activity.activityID)
		activityName = activity.activityName
		published = activity.published
		if let iconName = activity.iconNo {
			try icon = .icon(iconName: iconName)
		}
	}
}

extension NCDBRamAssemblyLineType {
	convenience init(_ assemblyLineType: AssemblyLineType) throws {
		self.init(context: .current)
		assemblyLineTypeID = Int32(assemblyLineType.assemblyLineTypeID)
		assemblyLineTypeName = assemblyLineType.assemblyLineTypeName
		baseTimeMultiplier = Float(assemblyLineType.baseTimeMultiplier)
		baseMaterialMultiplier = Float(assemblyLineType.baseMaterialMultiplier)
		baseCostMultiplier = Float(assemblyLineType.baseCostMultiplier)
		minCostPerHour = Float(assemblyLineType.minCostPerHour ?? 0)
		volume = Float(assemblyLineType.volume)
		try activity = ramActivities.get()[assemblyLineType.activityID]!.object()
	}
}

extension NCDBRamInstallationTypeContent {
	convenience init(_ installationTypeContent: InstallationTypeContent) throws {
		self.init(context: .current)
		quantity = Int32(installationTypeContent.quantity)
		try assemblyLineType = ramAssemblyLineTypes.get()[installationTypeContent.assemblyLineTypeID]!.object()
		try installationType = invTypes.get()[installationTypeContent.installationTypeID]!.object()
	}
}

extension NCDBNpcGroup {
	convenience init (_ npcGroup: NPCGroup) throws {
		self.init(context: .current)
		npcGroupName = npcGroup.groupName
		if let groupID = npcGroup.groupID {
			try group = invGroups.get()[groupID]!.object()
		}

		if let iconName = npcGroup.iconName {
			try icon = .icon(iconName: iconName)
		}

		try npcGroup.groups?.map { try NCDBNpcGroup($0) }.forEach {$0.parentNpcGroup = self}
	}
}

extension NCDBIndBlueprintType {
	convenience init? (_ blueprint: Blueprint) throws {
		guard let type = try invTypes.get()[blueprint.blueprintTypeID]?.object() else {return nil}
		self.init(context: .current)
		self.type = type
		maxProductionLimit = Int32(blueprint.maxProductionLimit)
		try [(blueprint.activities.manufacturing, 1),
		 (blueprint.activities.research_time, 3),
		 (blueprint.activities.research_material, 4),
		 (blueprint.activities.copying, 5),
		 (blueprint.activities.invention, 8),
		 (blueprint.activities.reaction, 11)].filter {$0.0 != nil}.forEach {
			try NCDBIndActivity($0.0!, ramActivity: ramActivities.get()[$0.1]!.object()).blueprintType = self
		}
		
		 
	}
}

extension NCDBIndActivity {
	convenience init (_ activity: Blueprint.Activities.Activity, ramActivity: NCDBRamActivity) throws {
		self.init(context: .current)
		self.activity = ramActivity
		try activity.materials?.forEach {
			try NCDBIndRequiredMaterial($0)?.activity = self
		}
		try activity.skills?.forEach {
			try NCDBIndRequiredSkill($0).activity = self
		}
		try activity.products?.forEach {
			try NCDBIndProduct($0)?.activity = self
		}
	}
}

extension NCDBIndRequiredMaterial {
	convenience init? (_ material: Blueprint.Activities.Activity.Material) throws {
		guard let type = try invTypes.get()[material.typeID]?.object() else {return nil}
		self.init(context: .current)
		quantity = Int32(material.quantity)
		materialType = type
	}
}

extension NCDBIndRequiredSkill {
	convenience init (_ skill: Blueprint.Activities.Activity.Skill) throws {
		self.init(context: .current)
		skillLevel = Int16(skill.level)
		try skillType = invTypes.get()[skill.typeID]!.object()
	}
}

extension NCDBIndProduct {
	convenience init? (_ product: Blueprint.Activities.Activity.Product) throws {
		guard let type = try invTypes.get()[product.typeID]?.object() else {return nil}
		self.init(context: .current)
		probability = Float(product.probability ?? 0)
		quantity = Int32(product.quantity)
		productType = type
	}
}

extension NCDBWhType {
	convenience init (_ type: NCDBInvType) throws {
		self.init(context: .current)
		let attributes = try typeAttributes.get()[Int(type.typeID)]
		self.type = type
		targetSystemClass = Int32(attributes?[1381]?.value ?? 0)
		maxStableTime = attributes?[1382]?.value ?? 0
		maxStableMass = attributes?[1383]?.value ?? 0
		maxRegeneration = attributes?[1384]?.value ?? 0
		maxJumpMass = attributes?[1385]?.value ?? 0
	}
}
