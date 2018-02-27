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
let storeURL = URL(fileURLWithPath: CommandLine.output)
try? FileManager.default.removeItem(at: storeURL)
try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: [NSSQLitePragmasOption:["journal_mode": "OFF"]])
let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
context.persistentStoreCoordinator = persistentStoreCoordinator

class NCDBImageValueTransformer: ValueTransformer {
	override func reverseTransformedValue(_ value: Any?) -> Any? {
		return value
	}
}
ValueTransformer.setValueTransformer(NCDBImageValueTransformer(), forName: NSValueTransformerName("NCDBImageValueTransformer"))


let root = URL(fileURLWithPath: CommandLine.input)

let availableCategoryIDs = [2,3,4,5,6,7,8,9,11,16,17,18,20,22,23,24,25,30,32,34,35,39,40,41,42,43,46,63,65,66,87,350001]

let iconIDs: Future<[Int: IconID]>
let invMetaGroups: Future<[Int: ObjectID<NCDBInvMetaGroup>]>
let metaTypes: Future<[Int: MetaType]>

let invCategories: Future<[Int: ObjectID<NCDBInvCategory>]>
let invGroups: Future<[Int: ObjectID<NCDBInvGroup>]>
let invTypes: Future<[Int: NCDBInvType]>
let invMarketGroups: Future<[Int: NCDBInvMarketGroup]>
let eveUnits: Future<[Int: NCDBEveUnit]>
let dgmAttributeCategories: Future<[Int: NCDBDgmAttributeCategory]>
let dgmAttributeTypes: Future<[Int: NCDBDgmAttributeType]>
let dgmEffects: Future<[Int: NCDBDgmEffect]>
let chrRaces: Future<[Int: NCDBChrRace]>
let chrFactions: Future<[Int: NCDBChrFaction]>
let certMasteryLevels: Future<[NCDBCertMasteryLevel]>
let invNames: Future<[Int: String]>

let universe: Future<[(String, [(Region, [(Constellation, [Future<SolarSystem>])])])]>
let mapUniverses: Future<[NCDBMapUniverse]>
let mapSolarSystems: Future<[Int: NCDBMapSolarSystem]>
let staStations: Future<[Int: NCDBStaStation]>
let mapDenormalize: Future<[Int: NCDBMapDenormalize]>

let ramActivities: Future<[Int:NCDBRamActivity]>
let ramAssemblyLineTypes: Future<[Int:NCDBRamAssemblyLineType]>

var eveIcons: [Int: NCDBEveIcon] = [:]
var typeIcons: [Int: NCDBEveIcon] = [:]
var nameIcons: [String: NCDBEveIcon] = [:]


let typeAttributes: Future<[Int: [Int: TypeAttribute]]>
let unpublishedMetaGroup: NCDBInvMetaGroup = {
	let ctx = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
	ctx.parent = context
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
	
	chrFactions = operationQueue.detach {
		let from = Date(); defer {print("chrRaces\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/chrFactions.json"), type: Schema.Factions.self).map {($0.factionID, try NCDBChrFaction($0))})
	}
	
	invMetaGroups = operationQueue.detach {
		let from = Date(); defer {print("invMetaGroups\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/invMetaGroups.json"), type: Schema.MetaGroups.self).map {($0.metaGroupID, .init(NCDBInvMetaGroup($0)))})
	}
	metaTypes = operationQueue.detach {
		let from = Date(); defer {print("metaTypes\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/invMetaTypes.json"), type: Schema.MetaTypes.self).map {($0.typeID, $0)})
	}
	
	invCategories = operationQueue.detach {
		let from = Date(); defer {print("invCategories\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/categoryIDs.json"), type: Schema.CategoryIDs.self).filter{availableCategoryIDs.contains($0.key)}.map{($0.key, try .init(NCDBInvCategory($0)))})
	}

	invGroups = operationQueue.detach {
		let from = Date(); defer {print("invGroups\t\(Date().timeIntervalSince(from))s")}
		let keys = try invCategories.get().keys
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/groupIDs.json"), type: Schema.GroupIDs.self).filter{keys.contains($0.value.categoryID)}.map{($0.key, try .init(NCDBInvGroup($0)))})
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

	dgmEffects = operationQueue.detach {
		let from = Date(); defer {print("dgmEffects\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/dgmEffects.json"), type: Schema.Effects.self).map {($0.effectID, NCDBDgmEffect($0))})
	}

	typeAttributes = operationQueue.detach {
		let from = Date(); defer {print("typeAttributes\t\(Date().timeIntervalSince(from))s")}
		var typeAttributes: [Int: [Int: TypeAttribute]] = [:]
		try load(root.appendingPathComponent("/sde/bsd/dgmTypeAttributes.json"), type: Schema.TypeAttributes.self).forEach { typeAttributes[$0.typeID, default: [:]][$0.attributeID] = $0 }
		return typeAttributes
	}

	
	_ = operationQueue.detach {
		let from = Date(); defer {print("typeEffects\t\(Date().timeIntervalSince(from))s")}
		let types = try invTypes.get()
		let effects = try dgmEffects.get()
		try load(root.appendingPathComponent("/sde/bsd/dgmTypeEffects.json"), type: Schema.TypeEffects.self).forEach { types[$0.typeID]?.addToEffects(effects[$0.effectID]!) }
	}
	
	certMasteryLevels = operationQueue.detach {
		let from = Date(); defer {print("certMasteryLevels\t\(Date().timeIntervalSince(from))s")}
		return try zip(["basic", "standard", "improved", "advanced", "elite"],
				["79_64_2", "79_64_3", "79_64_4", "79_64_5", "79_64_6"]).enumerated().map { (i, cert) in try NCDBCertMasteryLevel(level: i, name: cert.0, iconName: cert.1)
		}
	}
	
	_ = operationQueue.detach {
		let from = Date(); defer {print("certCertificates\t\(Date().timeIntervalSince(from))s")}
		try load(root.appendingPathComponent("/sde/fsd/certificates.json"), type: Schema.Certificates.self).forEach {
			_ = try NCDBCertCertificate($0)
		}
	}
	
	/*invNames = operationQueue.detach {
		let from = Date(); defer {print("invNames\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/invNames.json"), type: Schema.Names.self).map {($0.itemID, $0.itemName)})
	}

	universe = operationQueue.detach {
		let from = Date(); defer {print("universe\t\(Date().timeIntervalSince(from))s")}
		let fileManager = FileManager.default
		let universes = try load(root.appendingPathComponent("/sde/bsd/mapUniverse.json"), type: Schema.Universes.self)
		
		return try fileManager.contentsOfDirectory(at: root.appendingPathComponent("/sde/fsd/universe/"), includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsSubdirectoryDescendants])
			.filter {try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true}
			.map { url -> (String, [(Region, [(Constellation, [Future<SolarSystem>])])]) in
				return (url.lastPathComponent,
						try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsSubdirectoryDescendants]).filter {try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true}.map { url -> (Region, [(Constellation, [Future<SolarSystem>])]) in
							return try (load(url.appendingPathComponent("region.json")),
									try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsSubdirectoryDescendants]).filter {try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true}.map { url -> (Constellation, [Future<SolarSystem>]) in
										return try (load(url.appendingPathComponent("constellation.json")),
												try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsSubdirectoryDescendants]).filter {try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true}.map { url -> Future<SolarSystem> in
													operationQueue.detach {try load(url.appendingPathComponent("solarsystem.json"))}
											}
										)
								}
							)
					}
				)
		}
	}

	
	
	mapUniverses = operationQueue.detach {
		let from = Date(); defer {print("mapUniverses\t\(Date().timeIntervalSince(from))s")}
		let fileManager = FileManager.default
		let universes = try load(root.appendingPathComponent("/sde/bsd/mapUniverse.json"), type: Schema.Universes.self)
		
		return try universe.get().map {
			let universe = NCDBMapUniverse(context: context)
			switch $0.0 {
			case "wormhole":
				universe.name = universes.first {$0.universeID == 9000001}!.universeName
				universe.universeID = 9000001
			case "eve":
				universe.name = universes.first {$0.universeID == 9}!.universeName
				universe.universeID = 9
			default:
				throw DumpError.invalidUniverse($0.0)
			}

			try $0.1.forEach {
				let region = try NCDBMapRegion($0.0)
				region.universe = universe
				try $0.1.forEach {
					let constellation = try NCDBMapConstellation($0.0)
					constellation.region = region
					try $0.1.forEach {
						let solarSystem = try NCDBMapSolarSystem($0.get())
						solarSystem.constellation = constellation
					}
				}
			}
			return universe
		}
	}

	mapSolarSystems = operationQueue.detach {
		let from = Date(); defer {print("mapSolarSystems\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues:
			mapUniverses.get().flatMap {
				($0.regions as! Set<NCDBMapRegion>).map {
					($0.constellations as! Set<NCDBMapConstellation>).map {
						($0.solarSystems as! Set<NCDBMapSolarSystem>).map {(Int($0.solarSystemID), $0)}
						}.joined()
					}.joined()
				}.joined()
		)
	}

	staStations = operationQueue.detach {
		let from = Date(); defer {print("staStations\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/staStations.json"), type: Schema.Stations.self).map {($0.stationID, try NCDBStaStation($0))})
	}*/
	
	ramActivities = operationQueue.detach {
		let from = Date(); defer {print("ramActivities\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/ramActivities.json"), type: Schema.Activities.self).map {($0.activityID, try NCDBRamActivity($0))})
	}

	ramAssemblyLineTypes = operationQueue.detach {
		let from = Date(); defer {print("ramAssemblyLineTypes\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/ramAssemblyLineTypes.json"), type: Schema.AssemblyLineTypes.self).map {($0.assemblyLineTypeID, try NCDBRamAssemblyLineType($0))})
	}

	_ = operationQueue.detach {
		let from = Date(); defer {print("ramInstallationTypeContents\t\(Date().timeIntervalSince(from))s")}
		_ = try load(root.appendingPathComponent("/sde/bsd/ramInstallationTypeContents.json"), type: Schema.InstallationTypeContents.self).map {
			try NCDBRamInstallationTypeContent($0)
		}
	}

	_ = operationQueue.detach {
		let from = Date(); defer {print("npcGroups\t\(Date().timeIntervalSince(from))s")}
		let url = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().appendingPathComponent("npc.json")
		
		_ = try JSONDecoder().decode([NPCGroup].self, from: Data(contentsOf: url)).map { try NCDBNpcGroup($0) }
	}
	
	_ = operationQueue.detach {
		let from = Date(); defer {print("indBlueprints\t\(Date().timeIntervalSince(from))s")}
		_ = try load(root.appendingPathComponent("/sde/fsd/blueprints.json"), type: Schema.Blueprints.self).flatMap {
			try NCDBIndBlueprintType($0.value)
		}
	}
	
	_ = operationQueue.detach {
		let from = Date(); defer {print("whTypes\t\(Date().timeIntervalSince(from))s")}
		_ = try (invGroups.get()[988]!.object().types as! Set<NCDBInvType>).map {
			try NCDBWhType($0)
		}
	}

	operationQueue.waitUntilAllOperationsAreFinished()
	try context.save()
	
	_ = operationQueue.detach {
		let from = Date(); defer {print("dgmpp\t\(Date().timeIntervalSince(from))s")}
		try dgmpp()
	}


	/*mapDenormalize = operationQueue.detach {
		let from = Date(); defer {print("mapDenormalize\t\(Date().timeIntervalSince(from))s")}
		let stations = try Set(staStations.get().keys)
		let denormalize = try universe.get().map { try $0.1.map { try $0.1.map { try $0.1.map { solarSystem in
			try solarSystem.get().planets.values.map { planet -> [(Int, NCDBMapDenormalize)] in
				let npcStations = planet.npcStations?.filter {!stations.contains($0.key)}.map {$0}
				let moonStations = planet.moons?.flatMap { $0.1.npcStations?.filter {!stations.contains($0.key)} }
				return try [moonStations?.joined().map{$0}, npcStations].flatMap{ $0 }.joined().map{ station in
					try (station.key, NCDBMapDenormalize(station: station, solarSystem: solarSystem.get()))
				}
			}.joined()
			}.joined()}.joined()}.joined()}.joined()
		return try Dictionary.init(denormalize, uniquingKeysWith: { (_, _)
			in
			throw DumpError.npcStationsConflict
		})
	}*/

//	try Dictionary(uniqueKeysWithValues: metaTypesArray.get().map{($0.typeID, $0)})


	/*let categoryIDs: Future<Schema.CategoryIDs> = load(root.appendingPathComponent("/sde/fsd/categoryIDs.json"))
	let groupIDs: Future<Schema.GroupIDs> = load(root.appendingPathComponent("/sde/fsd/groupIDs.json"))
	let typeIDs: Future<Schema.TypeIDs> = load(root.appendingPathComponent("/sde/fsd/typeIDs.json"))
	let attributeCategories: Future<Schema.AttributeCategories> = load(root.appendingPathComponent("/sde/bsd/dgmAttributeCategories.json"))
	let attributeTypes: Future<Schema.AttributeTypes> = load(root.appendingPathComponent("/sde/bsd/dgmAttributeTypes.json"))
	try load(root.appendingPathComponent("/sde/bsd/dgmTypeAttributes.json"), type: Schema.TypeAttributes.self).get().forEach { typeAttributes[$0.typeID, default: [:]][$0.attributeID] = $0 }
	
	invGroups = try Dictionary(uniqueKeysWithValues: groupIDs.get().filter{invCategories.keys.contains($0.value.categoryID)}.map{($0.key, NCDBInvGroup($0))})
	
	metaTypes.forEach { invTypes[$0.key]?.parentType = invTypes[$0.value.parentTypeID] }

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

	
//	try categoryIDs.get()
//	try blueprints.get()
//	try certificates.get()
//	try groupIDs.get()
//	try iconIDs.get()
//	try solarSystems?.forEach {try $0.get()}
//	print("Done")*/
	
	operationQueue.waitUntilAllOperationsAreFinished()
	
	print("Save...")
	try context.save()

}
catch {
	print("\(error)")
}


