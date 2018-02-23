//
//  main.swift
//  sde-tool
//
//  Created by Artem Shimanski on 13.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

var args = [String: String]()

var key: String?
for arg in CommandLine.arguments[1...] {
	if arg.hasPrefix("-") {
		key = arg
	}
	else if let k = key {
		args[k] = arg
		key = nil
	}
	else {
		args["-i"] = arg
	}
}

extension CommandLine {
	static var output: String! = args["-o"]
	static var input: String! = args["-i"]!
}

guard CommandLine.output != nil && CommandLine.input != nil else {exit(EXIT_FAILURE)}

let managedObjectModel = NSManagedObjectModel.mergedModel(from: nil)!
let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: URL(fileURLWithPath: CommandLine.output), options: [NSSQLitePragmasOption:["journal_mode": "OFF"]])
let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
context.persistentStoreCoordinator = persistentStoreCoordinator


let root = URL(fileURLWithPath: CommandLine.input)

let availableCategoryIDs = [2,3,4,5,6,7,8,9,11,16,17,18,20,22,23,24,25,30,32,34,35,39,40,41,42,43,46,63,65,66,87,350001]

let iconIDs: Future<[Int: IconID]>
let invMetaGroups: Future<[Int: NCDBInvMetaGroup]>
let metaTypes: Future<[Int: MetaType]>

let invCategories: Future<[Int: NCDBInvCategory]>
let invGroups: Future<[Int: NCDBInvGroup]>
let invTypes: Future<[Int: NCDBInvType]>
let invMarketGroups: Future<[Int: NCDBInvMarketGroup]>
let eveUnits: Future<[Int: NCDBEveUnit]>
let dgmAttributeCategories: Future<[Int: NCDBDgmAttributeCategory]>
let dgmAttributeTypes: Future<[Int: NCDBDgmAttributeType]>
let chrRaces: Future<[Int: NCDBChrRace]>

var eveIcons: [Int: NCDBEveIcon] = [:]
var typeIcons: [Int: NCDBEveIcon] = [:]
var nameIcons: [String: NCDBEveIcon] = [:]


let typeAttributes: Future<[Int: [Int: TypeAttribute]]>
let unpublishedMetaGroup: NCDBInvMetaGroup = {
	let metaGroup = NCDBInvMetaGroup(context: context)
	metaGroup.metaGroupID = 1001
	metaGroup.metaGroupName = "Unpublished"
	return metaGroup
}()
let defaultMetaGroupID: Int = 1

let operationQueue = OperationQueue()

do {
	iconIDs = operationQueue.detach {
		let from = Date(); defer {print("iconIDs\t\(Date().timeIntervalSince(from))s")}
		return try load(root.appendingPathComponent("/sde/fsd/iconIDs.json"))
	}
	
	_ = operationQueue.detach {
		let from = Date(); defer {print("extraIcons\t\(Date().timeIntervalSince(from))s")}
		try ["9_64_7", "105_32_32", "50_64_13", "38_16_193", "38_16_194", "38_16_195", "38_16_174", "17_128_4", "74_64_14", "23_64_3", "18_128_2", "33_128_2", "79_64_1", "79_64_2", "79_64_3", "79_64_4", "79_64_5", "79_64_6"].forEach {
			if try NCDBEveIcon.icon(iconName: $0) == nil {
				print("Warning: missing icon \($0)")
			}
		}
	}
	
	chrRaces = operationQueue.detach {
		let from = Date(); defer {print("chrRaces\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/chrRaces.json"), type: Schema.Races.self).map {($0.raceID, try NCDBChrRace($0))})
	}
	
	invMetaGroups = operationQueue.detach {
		let from = Date(); defer {print("invMetaGroups\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/invMetaGroups.json"), type: Schema.MetaGroups.self).map {($0.metaGroupID, NCDBInvMetaGroup($0))})
	}
	metaTypes = operationQueue.detach {
		let from = Date(); defer {print("metaTypes\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/invMetaTypes.json"), type: Schema.MetaTypes.self).map {($0.typeID, $0)})
	}
	
	invCategories = operationQueue.detach {
		let from = Date(); defer {print("invCategories\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/categoryIDs.json"), type: Schema.CategoryIDs.self).filter{availableCategoryIDs.contains($0.key)}.map{($0.key, try NCDBInvCategory($0))})
	}

	invGroups = operationQueue.detach {
		let from = Date(); defer {print("invGroups\t\(Date().timeIntervalSince(from))s")}
		let keys = try invCategories.get().keys
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/groupIDs.json"), type: Schema.GroupIDs.self).filter{keys.contains($0.value.categoryID)}.map{($0.key, try NCDBInvGroup($0))})
	}
	
	invTypes = operationQueue.detach {
		let from = Date(); defer {print("invTypes\t\(Date().timeIntervalSince(from))s")}
		let keys = try invGroups.get().keys
		let typeIDs: Schema.TypeIDs = try load(root.appendingPathComponent("/sde/fsd/typeIDs.json"))
		
		return try Dictionary(uniqueKeysWithValues: typeIDs.filter{keys.contains($0.value.groupID)}.map{($0.key, try NCDBInvType($0, typeIDs: typeIDs))})
	}
	
	invMarketGroups = operationQueue.detach {
		let from = Date(); defer {print("invMarketGroups\t\(Date().timeIntervalSince(from))s")}
		var invMarketGroups = [Int: NCDBInvMarketGroup]()
		var queue = try load(root.appendingPathComponent("/sde/bsd/invMarketGroups.json"), type: Schema.MarketGroups.self)
		while !queue.isEmpty {
			let first = queue.removeFirst()
			if let parentGroupID = first.parentGroupID {
				if let parent = invMarketGroups[parentGroupID] {
					let marketGroup = try NCDBInvMarketGroup(first)
					marketGroup.parentGroup = parent
					invMarketGroups[first.marketGroupID] = marketGroup
				}
				else {
					queue.append(first)
				}
			}
			else {
				let marketGroup = try NCDBInvMarketGroup(first)
				invMarketGroups[first.marketGroupID] = marketGroup
			}
		}
		return invMarketGroups
	}
	
	_ = operationQueue.detach {
		let from = Date(); defer {print("invTypeRequiredSkill\t\(Date().timeIntervalSince(from))s")}
		let pairs: [(Int32, Int32)] = [(182, 277),
									   (183, 278),
									   (184, 279),
									   (1285, 1286),
									   (1289, 1287),
									   (1290, 1288)]
		let types = try invTypes.get()
		types.forEach { (_, type) in
			guard let attributes = type.attributes as? Set<NCDBDgmTypeAttribute> else {return}
			
			for i in pairs {
				guard let skillID = attributes.first(where: {$0.attributeType?.attributeID == i.0}),
					let skillLevel = attributes.first(where: {$0.attributeType?.attributeID == i.1}),
					let skill = types[Int(skillID.value)],
					Int32(skillID.value) != type.typeID else {continue}
				let requiredSkill = NCDBInvTypeRequiredSkill(context: context)
				requiredSkill.type = type
				requiredSkill.skillType = skill
				requiredSkill.skillLevel = Int16(skillLevel.value)
				
			}
		}
	}
	
	_ = operationQueue.detach {
		let from = Date(); defer {print("parentTypes\t\(Date().timeIntervalSince(from))s")}
		let types = try invTypes.get()
		try metaTypes.get().forEach { (typeID, value) in
			types[typeID]?.parentType = types[value.parentTypeID]!
		}
	}

	eveUnits = operationQueue.detach {
		let from = Date(); defer {print("eveUnits\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/eveUnits.json"), type: Schema.Units.self).map {($0.unitID, NCDBEveUnit($0))})
	}
	
	dgmAttributeCategories = operationQueue.detach {
		let from = Date(); defer {print("dgmAttributeCategories\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/dgmAttributeCategories.json"), type: Schema.AttributeCategories.self).map {($0.categoryID, NCDBDgmAttributeCategory($0))})
	}

	dgmAttributeTypes = operationQueue.detach {
		let from = Date(); defer {print("dgmAttributeTypes\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/dgmAttributeTypes.json"), type: Schema.AttributeTypes.self).map {($0.attributeID, try NCDBDgmAttributeType($0))})
	}

	typeAttributes = operationQueue.detach {
		let from = Date(); defer {print("typeAttributes\t\(Date().timeIntervalSince(from))s")}
		var typeAttributes: [Int: [Int: TypeAttribute]] = [:]
		try load(root.appendingPathComponent("/sde/bsd/dgmTypeAttributes.json"), type: Schema.TypeAttributes.self).forEach { typeAttributes[$0.typeID, default: [:]][$0.attributeID] = $0 }
		return typeAttributes
	}

//	try Dictionary(uniqueKeysWithValues: metaTypesArray.get().map{($0.typeID, $0)})


	/*let categoryIDs: Future<Schema.CategoryIDs> = load(root.appendingPathComponent("/sde/fsd/categoryIDs.json"))
	let groupIDs: Future<Schema.GroupIDs> = load(root.appendingPathComponent("/sde/fsd/groupIDs.json"))
	let typeIDs: Future<Schema.TypeIDs> = load(root.appendingPathComponent("/sde/fsd/typeIDs.json"))
	let attributeCategories: Future<Schema.AttributeCategories> = load(root.appendingPathComponent("/sde/bsd/dgmAttributeCategories.json"))
	let attributeTypes: Future<Schema.AttributeTypes> = load(root.appendingPathComponent("/sde/bsd/dgmAttributeTypes.json"))
	try load(root.appendingPathComponent("/sde/bsd/dgmTypeAttributes.json"), type: Schema.TypeAttributes.self).get().forEach { typeAttributes[$0.typeID, default: [:]][$0.attributeID] = $0 }
	
	invGroups = try Dictionary(uniqueKeysWithValues: groupIDs.get().filter{invCategories.keys.contains($0.value.categoryID)}.map{($0.key, NCDBInvGroup($0))})
	
	metaTypes.forEach { invTypes[$0.key]?.parentType = invTypes[$0.value.parentTypeID] }

	let blueprints: Future<Schema.Blueprints> = load(root.appendingPathComponent("/sde/fsd/blueprints.json"))
	let certificates: Future<Schema.Certificates> = load(root.appendingPathComponent("/sde/fsd/certificates.json"))
	let ancestries: Future<Schema.Ancestries> = load(root.appendingPathComponent("/sde/bsd/chrAncestries.json"))
	let bloodlines: Future<Schema.Bloodlines> = load(root.appendingPathComponent("/sde/bsd/chrBloodlines.json"))
	let factions: Future<Schema.Factions> = load(root.appendingPathComponent("/sde/bsd/chrFactions.json"))
	let races: Future<Schema.Races> = load(root.appendingPathComponent("/sde/bsd/chrRaces.json"))
	let units: Future<Schema.Units> = load(root.appendingPathComponent("/sde/bsd/eveUnits.json"))
	let flags: Future<Schema.Flags> = load(root.appendingPathComponent("/sde/bsd/invFlags.json"))
	let items: Future<Schema.Items> = load(root.appendingPathComponent("/sde/bsd/invItems.json"))
	let names: Future<Schema.Names> = load(root.appendingPathComponent("/sde/bsd/invNames.json"))
	let typeMaterials: Future<Schema.TypeMaterials> = load(root.appendingPathComponent("/sde/bsd/invTypeMaterials.json"))
	let typeReactions: Future<Schema.TypeReactions> = load(root.appendingPathComponent("/sde/bsd/invTypeReactions.json"))
	let planetSchematics: Future<Schema.PlanetSchematics> = load(root.appendingPathComponent("/sde/bsd/planetSchematics.json"))
	let planetSchematicsPinMaps: Future<Schema.PlanetSchematicsPinMaps> = load(root.appendingPathComponent("/sde/bsd/planetSchematicsPinMap.json"))
	let planetSchematicsTypeMaps: Future<Schema.PlanetSchematicsTypeMaps> = load(root.appendingPathComponent("/sde/bsd/planetSchematicsTypeMap.json"))
	let activities: Future<Schema.Activities> = load(root.appendingPathComponent("/sde/bsd/ramActivities.json"))
	let assemblyLineStations: Future<Schema.AssemblyLineStations> = load(root.appendingPathComponent("/sde/bsd/ramAssemblyLineStations.json"))
	let assemblyLineTypeDetailPerCategories: Future<Schema.AssemblyLineTypeDetailPerCategories> = load(root.appendingPathComponent("/sde/bsd/ramAssemblyLineTypeDetailPerCategory.json"))
	let assemblyLineTypeDetailPerGroups: Future<Schema.AssemblyLineTypeDetailPerGroups> = load(root.appendingPathComponent("/sde/bsd/ramAssemblyLineTypeDetailPerGroup.json"))
	let assemblyLineTypes: Future<Schema.AssemblyLineTypes> = load(root.appendingPathComponent("/sde/bsd/ramAssemblyLineTypes.json"))
	let installationTypeContents: Future<Schema.InstallationTypeContents> = load(root.appendingPathComponent("/sde/bsd/ramInstallationTypeContents.json"))
	let stations: Future<Schema.Stations> = load(root.appendingPathComponent("/sde/bsd/staStations.json"))
	let effects: Future<Schema.Effects> = load(root.appendingPathComponent("/sde/bsd/dgmEffects.json"))
	let typeEffects: Future<Schema.TypeEffects> = load(root.appendingPathComponent("/sde/bsd/dgmTypeEffects.json"))
	let regions = FileManager.default.enumerator(at: root.appendingPathComponent("/sde/fsd/universe/"), includingPropertiesForKeys: [])!.filter {($0 as? URL)?.lastPathComponent == "region.json"}.map { i -> Future<Region> in load(i as! URL) }
	let constellations = FileManager.default.enumerator(at: root.appendingPathComponent("/sde/fsd/universe/"), includingPropertiesForKeys: [])!.filter {($0 as? URL)?.lastPathComponent == "constellation.json"}.map { i -> Future<Constellation> in load(i as! URL) }
	let solarSystems = FileManager.default.enumerator(at: root.appendingPathComponent("/sde/fsd/universe/"), includingPropertiesForKeys: [])!.filter {($0 as? URL)?.lastPathComponent == "solarsystem.json"}.map { i -> Future<SolarSystem> in load(i as! URL) }*/

	
//	try categoryIDs.get()
//	try blueprints.get()
//	try certificates.get()
//	try groupIDs.get()
//	try iconIDs.get()
//	try solarSystems?.forEach {try $0.get()}
//	print("Done")
	
	_ = try invTypes.get()
}
catch {
	print("\(error)")
}

operationQueue.waitUntilAllOperationsAreFinished()
