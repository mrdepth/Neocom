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
let defaultMetaGroupID: Int = 1
let metaTypes: [Int: MetaType]

do {
	iconIDs = try load(root.appendingPathComponent("/sde/fsd/iconIDs.json")).get()
	invMetaGroups = try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/invMetaGroups.json"), type: Schema.MetaGroups.self).get().map {($0.metaGroupID, NCDBInvMetaGroup($0))})
	metaTypes = try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/invMetaTypes.json"), type: Schema.MetaTypes.self).get().map {($0.typeID, $0)})
	
	
//	try Dictionary(uniqueKeysWithValues: metaTypesArray.get().map{($0.typeID, $0)})


	let categoryIDs: Future<Schema.CategoryIDs> = load(root.appendingPathComponent("/sde/fsd/categoryIDs.json"))
	let groupIDs: Future<Schema.GroupIDs> = load(root.appendingPathComponent("/sde/fsd/groupIDs.json"))
	let typeIDs: Future<Schema.TypeIDs> = load(root.appendingPathComponent("/sde/fsd/typeIDs.json"))
	let attributeCategories: Future<Schema.AttributeCategories> = load(root.appendingPathComponent("/sde/bsd/dgmAttributeCategories.json"))
	let attributeTypes: Future<Schema.AttributeTypes> = load(root.appendingPathComponent("/sde/bsd/dgmAttributeTypes.json"))
	try load(root.appendingPathComponent("/sde/bsd/dgmTypeAttributes.json"), type: Schema.TypeAttributes.self).get().forEach { typeAttributes[$0.typeID, default: [:]][$0.attributeID] = $0 }
	
	invCategories = try Dictionary(uniqueKeysWithValues: categoryIDs.get().filter{availableCategoryIDs.contains($0.key)}.map{($0.key, NCDBInvCategory($0))})
	invGroups = try Dictionary(uniqueKeysWithValues: groupIDs.get().filter{invCategories.keys.contains($0.value.categoryID)}.map{($0.key, NCDBInvGroup($0))})
	invTypes = try Dictionary(uniqueKeysWithValues: typeIDs.get().filter{invGroups.keys.contains($0.value.groupID)}.map{($0.key, NCDBInvType($0))})
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
	let solarSystems = FileManager.default.enumerator(at: root.appendingPathComponent("/sde/fsd/universe/"), includingPropertiesForKeys: [])!.filter {($0 as? URL)?.lastPathComponent == "solarsystem.json"}.map { i -> Future<SolarSystem> in load(i as! URL) }

	
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

