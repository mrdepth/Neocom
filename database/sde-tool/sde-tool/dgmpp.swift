//
//  dgmpp.swift
//  sde-tool
//
//  Created by Artem Shimanski on 27.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

// MARK: dgmppItems
var dgmppItemGroups = [IndexPath: NCDBDgmppItemGroup]()

extension NCDBDgmppItemGroup {
	
	class func itemGroup(marketGroup: NCDBInvMarketGroup, category: NCDBDgmppItemCategory) -> NCDBDgmppItemGroup? {
		guard marketGroup.marketGroupID != 1659 else {return nil}
		let key = IndexPath(indexes: [Int(marketGroup.marketGroupID), Int(category.category), Int(category.subcategory), Int(category.race?.raceID ?? 0)])
		if let group = dgmppItemGroups[key] {
			return group
		}
		else {
			guard let group = NCDBDgmppItemGroup(marketGroup: marketGroup, category: category) else {return nil}
			dgmppItemGroups[key] = group
			return group
		}
	}
	
	convenience init?(marketGroup: NCDBInvMarketGroup, category: NCDBDgmppItemCategory) {
		var parentGroup: NCDBDgmppItemGroup?
		if let parentMarketGroup = marketGroup.parentGroup {
			parentGroup = NCDBDgmppItemGroup.itemGroup(marketGroup: parentMarketGroup, category: category)
			if parentGroup == nil {
				return nil
			}
		}
		
		self.init(context: .current)
		groupName = marketGroup.marketGroupName
		icon = marketGroup.icon
		self.parentGroup = parentGroup
		self.category = category
	}
}

extension NCDBDgmppItemCategory {
	convenience init(categoryID: NCDBDgmppItemCategoryID, subcategory: Int32 = 0, race: NCDBChrRace? = nil) {
		self.init(context: .current)
		self.category = categoryID.rawValue
		self.subcategory = subcategory
		self.race = race
	}
}

func dgmpp() throws {

	func compress(itemGroup: NCDBDgmppItemGroup) -> NCDBDgmppItemGroup {
		if itemGroup.subGroups?.count == 1 {
			let child = itemGroup.subGroups?.anyObject() as? NCDBDgmppItemGroup
			
			itemGroup.addToItems(child!.items!)
			itemGroup.addToSubGroups(child!.subGroups!)
			child!.removeFromItems(child!.items!)
			child!.removeFromSubGroups(child!.subGroups!)
			child?.category = nil
			child?.parentGroup = nil
			itemGroup.managedObjectContext?.delete(child!)
			if let i = dgmppItemGroups.index(where: {$0.value == child}) {
				dgmppItemGroups.remove(at: i)
			}
		}
		guard let parent = itemGroup.parentGroup else {return itemGroup}
		return compress(itemGroup: parent)
	}
	
	func trim(_ itemGroups: Set<NCDBDgmppItemGroup>) -> [NCDBDgmppItemGroup] {
		func leaf(_ itemGroup: NCDBDgmppItemGroup) -> NCDBDgmppItemGroup? {
			guard let parent = itemGroup.parentGroup else {return itemGroup}
			return leaf(parent)
		}
		
		var leaves: Set<NCDBDgmppItemGroup>? = itemGroups
		while leaves?.count == 1 {
			let leaf = leaves?.first
			if let subGroups = leaf?.subGroups as? Set<NCDBDgmppItemGroup> {
				leaves = leaf?.subGroups as? Set<NCDBDgmppItemGroup>
				leaf?.removeFromSubGroups(subGroups as NSSet)
				leaf?.category = nil
				leaf?.parentGroup = nil
				leaf?.removeFromItems(leaf!.items!)
				leaf?.managedObjectContext?.delete(leaf!)
				if let i = dgmppItemGroups.index(where: {$0.value == leaf}) {
					dgmppItemGroups.remove(at: i)
				}
			}
		}
		//print ("\(Array(leaves!).flatMap {$0.groupName} )")
		return Array(leaves ?? Set())
	}
	
	func importItems(types: [NCDBInvType], category: NCDBDgmppItemCategory, categoryName: String) throws {
		let groups = Set(types.flatMap { type -> NCDBDgmppItemGroup? in
			guard let marketGroup = type.marketGroup else {return nil}
			guard let group = NCDBDgmppItemGroup.itemGroup(marketGroup: marketGroup, category: category) else {return nil}
			type.dgmppItem = NCDBDgmppItem(context: .current)
			group.addToItems(type.dgmppItem!)
			return group
		})
		
		let leaves = Set(groups.map { compress(itemGroup: $0) })
		
		let root = NCDBDgmppItemGroup(context: .current)
		root.groupName = categoryName
		root.category = category
		let trimmed = trim(leaves)
		if trimmed.count == 0 {
			for type in types {
				type.dgmppItem?.addToGroups(root)
			}
		}
		for group in trimmed {
			group.parentGroup = root
		}
	}
	
	func importItems(category: NCDBDgmppItemCategory, categoryName: String, predicate: NSPredicate) throws {
		let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
		request.predicate = predicate
		let types = try NSManagedObjectContext.current.fetch(request)
		try importItems(types: types, category: category, categoryName: categoryName)
	}
	
	
	
	func tablesFrom(conditions: [String]) throws -> Set<String> {
		var tables = Set<String>()
		let expression = try NSRegularExpression(pattern: "\\b([a-zA-Z]{1,}?)\\.[a-zA-Z]{1,}?\\b", options: [.caseInsensitive])
		for condition in conditions {
			let s = condition as NSString
			for result in expression.matches(in: condition, options: [], range: NSMakeRange(0, s.length)) {
				tables.insert(s.substring(with: result.range(at: 1)))
			}
		}
		return tables
	}
	
	try importItems(category: NCDBDgmppItemCategory(categoryID: .ship), categoryName: "Ships", predicate: NSPredicate(format: "group.category.categoryID == 6"))
	try importItems(category: NCDBDgmppItemCategory(categoryID: .drone), categoryName: "Drones", predicate: NSPredicate(format: "group.category.categoryID == 18"))
	try importItems(category: NCDBDgmppItemCategory(categoryID: .fighter), categoryName: "Fighters", predicate: NSPredicate(format: "group.category.categoryID == 87 AND ANY attributes.attributeType.attributeID IN (%@)", [2212, 2213, 2214]))
	try importItems(category: NCDBDgmppItemCategory(categoryID: .structureFighter), categoryName: "Fighters", predicate: NSPredicate(format: "group.category.categoryID == 87 AND ANY attributes.attributeType.attributeID IN (%@)", [2740, 2741, 2742]))
	try importItems(category: NCDBDgmppItemCategory(categoryID: .structure), categoryName: "Structures", predicate: NSPredicate(format: "marketGroup.parentGroup.marketGroupID == 2199 OR marketGroup.marketGroupID == 2324 OR marketGroup.marketGroupID == 2327"))
	
	for subcategory in [7, 66] as [Int32] {
		try importItems(category: NCDBDgmppItemCategory(categoryID: .hi, subcategory: subcategory), categoryName: "Hi Slot", predicate: NSPredicate(format: "group.category.categoryID == %d AND ANY effects.effectID == 12", subcategory))
		try importItems(category: NCDBDgmppItemCategory(categoryID: .med, subcategory: subcategory), categoryName: "Med Slot", predicate: NSPredicate(format: "group.category.categoryID == %d AND ANY effects.effectID == 13", subcategory))
		try importItems(category: NCDBDgmppItemCategory(categoryID: .low, subcategory: subcategory), categoryName: "Low Slot", predicate: NSPredicate(format: "group.category.categoryID == %d AND ANY effects.effectID == 11", subcategory))
		
		let request = NSFetchRequest<NSDictionary>(entityName: "DgmTypeAttribute")
		request.predicate = NSPredicate(format: "attributeType.attributeID == 1547 AND ANY type.effects.effectID == 2663 AND type.group.category.categoryID ==  %d", subcategory)
		request.propertiesToGroupBy = ["value"]
		request.propertiesToFetch = ["value"]
		request.resultType = .dictionaryResultType
		try NSManagedObjectContext.current.fetch(request).forEach { i in
			let value = i["value"] as! NSNumber
			try importItems(category: NCDBDgmppItemCategory(categoryID: subcategory == 7 ? .rig : .structureRig, subcategory: value.int32Value), categoryName: "Rig Slot", predicate: NSPredicate(format: "group.category.categoryID == %d AND ANY effects.effectID == 2663 AND SUBQUERY(attributes, $attribute, $attribute.attributeType.attributeID == 1547 AND $attribute.value == %f).@count > 0", subcategory, value.floatValue))
		}

//		try database.exec("select value from dgmTypeAttributes as a, dgmTypeEffects as b, invTypes as c, invGroups as d where b.effectID = 2663 AND attributeID=1547 AND a.typeID=b.typeID AND b.typeID=c.typeID AND c.groupID = d.groupID AND d.categoryID = \(subcategory) group by value;") { row in
//		}
	}
	
	do {
		let request = NSFetchRequest<NSDictionary>(entityName: "InvType")
		request.predicate = NSPredicate(format: "ANY effects.effectID == 3772")
		request.propertiesToGroupBy = ["race"]
		request.propertiesToFetch = ["race"]
		request.resultType = .dictionaryResultType
		try NSManagedObjectContext.current.fetch(request).forEach { i in
			let race = try NSManagedObjectContext.current.existingObject(with: i["race"] as! NSManagedObjectID) as! NCDBChrRace
			try importItems(category: NCDBDgmppItemCategory(categoryID: .subsystem, subcategory: 7, race: race), categoryName: "Subsystems", predicate: NSPredicate(format: "ANY effects.effectID == 3772 AND race == %@", race))
		}
	}
	
	
//	try database.exec("select raceID from invTypes as a, dgmTypeEffects as b where b.effectID = 3772 AND a.typeID=b.typeID group by raceID;") { row in
//		let raceID = row["raceID"] as! NSNumber
//		let race = chrRaces[raceID]
//		importItems(category: NCDBDgmppItemCategory(categoryID: .subsystem, subcategory: 7, race: race), categoryName: "Subsystems", predicate: NSPredicate(format: "ANY effects.effectID == 3772 AND race.raceID == %@", raceID))
//	}
	
	try importItems(category: NCDBDgmppItemCategory(categoryID: .service, subcategory: 66), categoryName: "Service Slot", predicate: NSPredicate(format: "group.category.categoryID == 66 AND ANY effects.effectID == 6306"))
	
	do {
		let request = NSFetchRequest<NSDictionary>(entityName: "DgmTypeAttribute")
		request.predicate = NSPredicate(format: "attributeType.attributeID == 331 AND type.marketGroup != nil")
		request.propertiesToGroupBy = ["value"]
		request.propertiesToFetch = ["value"]
		request.resultType = .dictionaryResultType
		try NSManagedObjectContext.current.fetch(request).forEach { attribute in
			let value = attribute["value"] as! Float
			let request = NSFetchRequest<NCDBDgmTypeAttribute>(entityName: "DgmTypeAttribute")
			request.predicate = NSPredicate(format: "attributeType.attributeID == 331 AND value == %f", value)
			let attributes = (try NSManagedObjectContext.current.fetch(request))
			try importItems(types: attributes.map{$0.type!}, category: NCDBDgmppItemCategory(categoryID: .implant, subcategory: Int32(value)), categoryName: "Implants")
		}
	}
	
//	try database.exec("select value from dgmTypeAttributes as a, invTypes as b where attributeID=331 and a.typeID=b.typeID and b.marketGroupID > 0 group by value;") { row in
//		let value = row["value"] as! NSNumber
//		let request = NSFetchRequest<NCDBDgmTypeAttribute>(entityName: "DgmTypeAttribute")
//		request.predicate = NSPredicate(format: "attributeType.attributeID == 331 AND value == %@", value)
//		let attributes = (try NSManagedObjectContext.current.fetch(request))
//		importItems(types: attributes.map{$0.type!}, category: NCDBDgmppItemCategory(categoryID: .implant, subcategory: value.int32Value), categoryName: "Implants")
//	}
	
	do {
		let request = NSFetchRequest<NSDictionary>(entityName: "DgmTypeAttribute")
		request.predicate = NSPredicate(format: "attributeType.attributeID == 1087 AND type.marketGroup != nil")
		request.propertiesToGroupBy = ["value"]
		request.propertiesToFetch = ["value"]
		request.resultType = .dictionaryResultType
		try NSManagedObjectContext.current.fetch(request).forEach { attribute in
			let value = attribute["value"] as! Float
			let request = NSFetchRequest<NCDBDgmTypeAttribute>(entityName: "DgmTypeAttribute")
			request.predicate = NSPredicate(format: "attributeType.attributeID == 1087 AND value == %f", value)
			let attributes = (try NSManagedObjectContext.current.fetch(request))
			try importItems(types: attributes.map{$0.type!}, category: NCDBDgmppItemCategory(categoryID: .booster, subcategory: Int32(value)), categoryName: "Implants")
		}
	}

//	try database.exec("select value from dgmTypeAttributes as a, invTypes as b where attributeID=1087 and a.typeID=b.typeID and b.marketGroupID > 0 group by value;") { row in
//		let value = row["value"] as! NSNumber
//		let request = NSFetchRequest<NCDBDgmTypeAttribute>(entityName: "DgmTypeAttribute")
//		request.predicate = NSPredicate(format: "attributeType.attributeID == 1087 AND value == %@", value)
//		let attributes = (try NSManagedObjectContext.current.fetch(request))
//		importItems(types: attributes.map{$0.type!}, category: NCDBDgmppItemCategory(categoryID: .booster, subcategory: value.int32Value), categoryName: "Boosters")
//	}
	
	do {
		try zip(["Confessor", "Svipul", "Jackdaw", "Hecate"],
			[["Confessor Defense Mode", "Confessor Sharpshooter Mode", "Confessor Propulsion Mode"],
			 ["Svipul Defense Mode", "Svipul Sharpshooter Mode", "Svipul Propulsion Mode"],
			 ["Jackdaw Defense Mode", "Jackdaw Sharpshooter Mode", "Jackdaw Propulsion Mode"],
			 ["Hecate Defense Mode", "Hecate Sharpshooter Mode", "Hecate Propulsion Mode"]]).forEach { i in
				let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
				request.predicate = NSPredicate(format: "typeName == %@", i.0)
				let ship = try NSManagedObjectContext.current.fetch(request).first!
				
				let root = NCDBDgmppItemGroup(context: .current)
				root.category = NCDBDgmppItemCategory(categoryID: .mode, subcategory: ship.typeID)
				root.groupName = "Tactical Mode"

				for mode in i.1 {
					request.predicate = NSPredicate(format: "typeName == %@", mode)
					let type = try NSManagedObjectContext.current.fetch(request).first!
					type.dgmppItem = NCDBDgmppItem(context: .current)
					root.addToItems(type.dgmppItem!)
				}
		}
	}
	
	/*try database.exec("SELECT typeID FROM dgmTypeAttributes WHERE attributeID=10000") { row in
		let typeID = row["typeID"] as! NSNumber
		let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
		request.predicate = NSPredicate(format: "ANY effects.effectID == 10002 AND SUBQUERY(attributes, $attribute, $attribute.attributeType.attributeID == 1302 AND $attribute.value == %@).@count > 0", typeID)
		let root = NCDBDgmppItemGroup(context: .current)
		root.category = NCDBDgmppItemCategory(categoryID: .mode, subcategory: typeID.int32Value)
		root.groupName = "Tactical Mode"
		for type in try NSManagedObjectContext.current.fetch(request) {
			type.dgmppItem = NCDBDgmppItem(context: .current)
			root.addToItems(type.dgmppItem!)
		}
	}*/
	
	
	var chargeCategories = [IndexPath: NCDBDgmppItemCategory]()
	let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
	let attributeIDs = Set<Int32>([604, 605, 606, 609, 610])
	request.predicate = NSPredicate(format: "ANY attributes.attributeType.attributeID IN (%@)", attributeIDs)
	for type in try NSManagedObjectContext.current.fetch(request) {
		let attributes = type.attributes?.allObjects as? [NCDBDgmTypeAttribute]
		let chargeSize = attributes?.first(where: {$0.attributeType?.attributeID == 128})?.value
		var chargeGroups: Set<Int> = Set()
		for attribute in attributes?.filter({attributeIDs.contains($0.attributeType!.attributeID)}) ?? [] {
			chargeGroups.insert(Int(attribute.value))
		}
		
		if !chargeGroups.isEmpty {
			var array = chargeGroups.sorted()
			if let chargeSize = chargeSize {
				array.append(Int(chargeSize))
			}
			else {
				array.append(Int(type.capacity * 100))
			}
			let key = IndexPath(indexes: array)
			if let category = chargeCategories[key] {
				type.dgmppItem?.charge = category
			}
			else {
				let root = NCDBDgmppItemGroup(context: .current)
				root.groupName = "Ammo"
				root.category = NCDBDgmppItemCategory(categoryID: .charge, subcategory: Int32(chargeSize ?? 0), race: nil)
				type.dgmppItem?.charge = root.category
				chargeCategories[key] = root.category!
				
				let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
				if let chargeSize = chargeSize {
					request.predicate = NSPredicate(format: "group.groupID IN %@ AND published = 1 AND SUBQUERY(attributes, $attribute, $attribute.attributeType.attributeID == 128 AND $attribute.value == %d).@count > 0", chargeGroups, Int(chargeSize))
				}
				else {
					request.predicate = NSPredicate(format: "group.groupID IN %@ AND published = 1 AND volume <= %f", chargeGroups, type.capacity)
				}
				for charge in try NSManagedObjectContext.current.fetch(request) {
					if charge.dgmppItem == nil {
						charge.dgmppItem = NCDBDgmppItem(context: .current)
					}
					root.addToItems(charge.dgmppItem!)
					//charge.dgmppItem?.addToGroups(root)
				}
			}
			
		}
	}
	
	print ("dgmppItems info")
	request.predicate = NSPredicate(format: "dgmppItem <> NULL")
	for type in try NSManagedObjectContext.current.fetch(request) {
		let attributes = try typeAttributes.get()[Int(type.typeID)]
		switch NCDBDgmppItemCategoryID(rawValue: (type.dgmppItem!.groups!.anyObject() as! NCDBDgmppItemGroup).category!.category)! {
		case .hi, .med, .low, .rig, .structureRig:
			type.dgmppItem?.requirements = NCDBDgmppItemRequirements(context: .current)
			type.dgmppItem?.requirements?.powerGrid = Float(attributes?[30]?.value ?? 0)
			type.dgmppItem?.requirements?.cpu = Float(attributes?[50]?.value ?? 0)
			type.dgmppItem?.requirements?.calibration = Float(attributes?[1153]?.value ?? 0)
		case .charge, .drone, .fighter, .structureFighter:
			var multiplier = max(attributes?[64]?.value ?? 0, attributes?[212]?.value ?? 0)
			if multiplier == 0 {
				multiplier = 1
			}
			let em = (attributes?[114]?.value ?? 0) * multiplier
			let kinetic = (attributes?[117]?.value ?? 0) * multiplier
			let thermal = (attributes?[118]?.value ?? 0) * multiplier
			let explosive = (attributes?[116]?.value ?? 0) * multiplier
			if em + kinetic + thermal + explosive > 0 {
				type.dgmppItem?.damage = NCDBDgmppItemDamage(context: .current)
				type.dgmppItem?.damage?.emAmount = Float(em)
				type.dgmppItem?.damage?.kineticAmount = Float(kinetic)
				type.dgmppItem?.damage?.thermalAmount = Float(thermal)
				type.dgmppItem?.damage?.explosiveAmount = Float(explosive)
			}
		case .ship:
			type.dgmppItem?.shipResources = NCDBDgmppItemShipResources(context: .current)
			type.dgmppItem?.shipResources?.hiSlots = Int16(attributes?[14]?.value ?? 0)
			type.dgmppItem?.shipResources?.medSlots = Int16(attributes?[13]?.value ?? 0)
			type.dgmppItem?.shipResources?.lowSlots = Int16(attributes?[12]?.value ?? 0)
			type.dgmppItem?.shipResources?.rigSlots = Int16(attributes?[1137]?.value ?? 0)
			type.dgmppItem?.shipResources?.turrets = Int16(attributes?[102]?.value ?? 0)
			type.dgmppItem?.shipResources?.launchers = Int16(attributes?[101]?.value ?? 0)
		case .structure:
			type.dgmppItem?.structureResources = NCDBDgmppItemStructureResources(context: .current)
			type.dgmppItem?.structureResources?.hiSlots = Int16(attributes?[14]?.value ?? 0)
			type.dgmppItem?.structureResources?.medSlots = Int16(attributes?[13]?.value ?? 0)
			type.dgmppItem?.structureResources?.lowSlots = Int16(attributes?[12]?.value ?? 0)
			type.dgmppItem?.structureResources?.rigSlots = Int16(attributes?[1137]?.value ?? 0)
			type.dgmppItem?.structureResources?.serviceSlots = Int16(attributes?[2056]?.value ?? 0)
			type.dgmppItem?.structureResources?.turrets = Int16(attributes?[102]?.value ?? 0)
			type.dgmppItem?.structureResources?.launchers = Int16(attributes?[101]?.value ?? 0)
		default:
			break
		}
	}
	
	print ("dgmppHullTypes")
	
	do {
		func types(_ marketGroup: NCDBInvMarketGroup) -> [NCDBInvType] {
			var array = (marketGroup.types?.allObjects as? [NCDBInvType]) ?? []
			for group in marketGroup.subGroups?.allObjects ?? [] {
				array.append(contentsOf: types(group as! NCDBInvMarketGroup))
			}
			return array
		}
		
		for marketGroup in try invMarketGroups.get()[4]!.object().subGroups! {
			let marketGroup = marketGroup as! NCDBInvMarketGroup
			let hullType = NCDBDgmppHullType(context: .current)
			hullType.hullTypeName = marketGroup.marketGroupName
			
			let ships = Set(types(marketGroup))
			hullType.addToTypes(ships as NSSet)
			
			let array = try ships.flatMap {try typeAttributes.get()[Int($0.typeID)]?[552]?.value}.map{ Double($0) }
			var signature = array.reduce(0, +)
			signature /= Double(array.count)
			signature = ceil(signature / 5) * 5
			
			hullType.signature = Float(signature)
		}
		
	}
	
//	try database.exec("SELECT * FROM version") { row in
//		let version = NCDBVersion(context: .current)
//		version.expansion = expansion
//		version.build = Int32(row["build"] as! NSNumber)
//		version.version = row["version"] as? String
//	}
	
	
//	print ("Save...")
}
