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


let root = CommandLine.arguments[1]
let availableCategoryIDs = [2,3,4,5,6,7,8,9,11,16,17,18,20,22,23,24,25,30,32,34,35,39,40,41,42,43,46,63,65,66,87,350001]

let invCategories: [Int: NCDBInvCategory]
let invGroups: [Int: NCDBInvGroup]
let invTypes: [Int: NCDBInvType]
var eveIcons: [Int: NCDBEveIcon] = [:]
var typeIcons: [Int: NCDBEveIcon] = [:]

let iconIDs: [Int: IconID]
var typeAttributes: [Int: [Int: TypeAttribute]] = [:]
var invMetaGroups: [Int: NCDBInvMetaGroup]
let unpublishedMetaGroup: NCDBInvMetaGroup = {
	let metaGroup = NCDBInvMetaGroup(context: context)
	metaGroup.metaGroupID = 1001
	metaGroup.metaGroupName = "Unpublished"
	return metaGroup
}()
let defaultMetaGroup: NCDBInvMetaGroup

do {
	iconIDs = try load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/iconIDs.json")).get()
	let metaGroups: Future<Schema.MetaGroups> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/invMetaGroups.json"))
	
	invMetaGroups = try Dictionary(uniqueKeysWithValues: metaGroups.get().map{($0.metaGroupID, NCDBInvMetaGroup($0))})
	defaultMetaGroup = invMetaGroups[1]!

	let categoryIDs: Future<Schema.CategoryIDs> = load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/categoryIDs.json"))
	let groupIDs: Future<Schema.GroupIDs> = load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/groupIDs.json"))
	let typeIDs: Future<Schema.TypeIDs> = load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/typeIDs.json"))
	let attributeCategories: Future<Schema.AttributeCategories> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/dgmAttributeCategories.json"))
	let attributeTypes: Future<Schema.AttributeTypes> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/dgmAttributeTypes.json"))
	let typeAttributesArray: Future<Schema.TypeAttributes> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/dgmTypeAttributes.json"))
	try typeAttributesArray.get().forEach { typeAttributes[$0.typeID, default: [:]][$0.attributeID] = $0 }
	
	invCategories = try Dictionary(uniqueKeysWithValues: categoryIDs.get().filter{availableCategoryIDs.contains($0.key)}.map{($0.key, NCDBInvCategory($0))})
	invGroups = try Dictionary(uniqueKeysWithValues: groupIDs.get().filter{invCategories.keys.contains($0.value.categoryID)}.map{($0.key, NCDBInvGroup($0))})
	invTypes = try Dictionary(uniqueKeysWithValues: typeIDs.get().filter{invGroups.keys.contains($0.value.groupID)}.map{($0.key, NCDBInvType($0))})

	let blueprints: Future<Schema.Blueprints> = load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/blueprints.json"))
	let certificates: Future<Schema.Certificates> = load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/certificates.json"))
	let ancestries: Future<Schema.Ancestries> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/chrAncestries.json"))
	let bloodlines: Future<Schema.Bloodlines> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/chrBloodlines.json"))
	let factions: Future<Schema.Factions> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/chrFactions.json"))
	let races: Future<Schema.Races> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/chrRaces.json"))
	let units: Future<Schema.Units> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/eveUnits.json"))
	let flags: Future<Schema.Flags> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/invFlags.json"))
	let items: Future<Schema.Items> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/invItems.json"))
	let marketGroups: Future<Schema.MarketGroups> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/invMarketGroups.json"))
	let metaGroups: Future<Schema.MetaGroups> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/invMetaGroups.json"))
	let metaTypes: Future<Schema.MetaTypes> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/invMetaTypes.json"))
	let names: Future<Schema.Names> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/invNames.json"))
	let typeMaterials: Future<Schema.TypeMaterials> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/invTypeMaterials.json"))
	let typeReactions: Future<Schema.TypeReactions> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/invTypeReactions.json"))
	let planetSchematics: Future<Schema.PlanetSchematics> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/planetSchematics.json"))
	let planetSchematicsPinMaps: Future<Schema.PlanetSchematicsPinMaps> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/planetSchematicsPinMap.json"))
	let planetSchematicsTypeMaps: Future<Schema.PlanetSchematicsTypeMaps> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/planetSchematicsTypeMap.json"))
	let activities: Future<Schema.Activities> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/ramActivities.json"))
	let assemblyLineStations: Future<Schema.AssemblyLineStations> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/ramAssemblyLineStations.json"))
	let assemblyLineTypeDetailPerCategories: Future<Schema.AssemblyLineTypeDetailPerCategories> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/ramAssemblyLineTypeDetailPerCategory.json"))
	let assemblyLineTypeDetailPerGroups: Future<Schema.AssemblyLineTypeDetailPerGroups> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/ramAssemblyLineTypeDetailPerGroup.json"))
	let assemblyLineTypes: Future<Schema.AssemblyLineTypes> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/ramAssemblyLineTypes.json"))
	let installationTypeContents: Future<Schema.InstallationTypeContents> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/ramInstallationTypeContents.json"))
	let stations: Future<Schema.Stations> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/staStations.json"))
	let effects: Future<Schema.Effects> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/dgmEffects.json"))
	let typeEffects: Future<Schema.TypeEffects> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/dgmTypeEffects.json"))
	let regions = FileManager.default.enumerator(at: URL(fileURLWithPath: root).appendingPathComponent("/fsd/universe/"), includingPropertiesForKeys: [])!.filter {($0 as? URL)?.lastPathComponent == "region.json"}.map { i -> Future<Region> in load(i as! URL) }
	let constellations = FileManager.default.enumerator(at: URL(fileURLWithPath: root).appendingPathComponent("/fsd/universe/"), includingPropertiesForKeys: [])!.filter {($0 as? URL)?.lastPathComponent == "constellation.json"}.map { i -> Future<Constellation> in load(i as! URL) }
	let solarSystems = FileManager.default.enumerator(at: URL(fileURLWithPath: root).appendingPathComponent("/fsd/universe/"), includingPropertiesForKeys: [])!.filter {($0 as? URL)?.lastPathComponent == "solarsystem.json"}.map { i -> Future<SolarSystem> in load(i as! URL) }

	
//	try categoryIDs.get()
//	try blueprints.get()
//	try certificates.get()
//	try groupIDs.get()
//	try iconIDs.get()
//	try solarSystems?.forEach {try $0.get()}
//	print("Done")
}
catch {
	print("\(error)")
}

