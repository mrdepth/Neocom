//
//  main.swift
//  sde-tool
//
//  Created by Artem Shimanski on 13.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

let root = CommandLine.arguments[1]


do {
	let categoryIDs: Future<Schema.CategoryIDs> = load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/categoryIDs.json"))
	let blueprints: Future<Schema.Blueprints> = load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/blueprints.json"))
	let certificates: Future<Schema.Certificates> = load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/certificates.json"))
	let groupIDs: Future<Schema.GroupIDs> = load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/groupIDs.json"))
	let iconIDs: Future<Schema.IconIDs> = load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/iconIDs.json"))
	let typeIDs: Future<Schema.TypeIDs> = load(URL(fileURLWithPath: root).appendingPathComponent("/fsd/typeIDs.json"))
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
	let attributeCategories: Future<Schema.AttributeCategories> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/dgmAttributeCategories.json"))
	let attributeTypes: Future<Schema.AttributeTypes> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/dgmAttributeTypes.json"))
	let typeAttributes: Future<Schema.TypeAttributes> = load(URL(fileURLWithPath: root).appendingPathComponent("/bsd/dgmTypeAttributes.json"))
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

