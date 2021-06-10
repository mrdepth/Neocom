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

var localization = \LocalizedString.en

extension CommandLine {
    static var output: String! = args["-o"]
    static var input: String! = args["-i"]!
    static var locale: String? = args["-l"]
}



extension LocalizedString {
    var localized: String? {
        self[keyPath: localization] ?? self.en
    }
}

switch CommandLine.locale {
case "de":
    localization = \.de
case "en":
    localization = \.en
case "es":
    localization = \.es
case "fr":
    localization = \.fr
case "it":
    localization = \.it
case "ja":
    localization = \.ja
case "ru":
    localization = \.ru
case "zh":
    localization = \.zh
case "ko":
    localization = \.ko
default:
    break
}




guard CommandLine.output != nil && CommandLine.input != nil else {exit(EXIT_FAILURE)}

class ImageValueTransformer: ValueTransformer {
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        return value
    }
}

class NeocomSecureUnarchiveFromDataTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass]  {
        super.allowedTopLevelClasses + [NSAttributedString.self]
    }
}

ValueTransformer.setValueTransformer(ImageValueTransformer(), forName: NSValueTransformerName("ImageValueTransformer"))
ValueTransformer.setValueTransformer(NeocomSecureUnarchiveFromDataTransformer(), forName: NSValueTransformerName("NeocomSecureUnarchiveFromDataTransformer"))

let managedObjectModel = NSManagedObjectModel.mergedModel(from: nil)!
let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
let storeURL = URL(fileURLWithPath: CommandLine.output)
try? FileManager.default.removeItem(at: storeURL)
try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: "SDE", at: storeURL, options: [NSSQLitePragmasOption:["journal_mode": "OFF"]])
let mainContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
mainContext.persistentStoreCoordinator = persistentStoreCoordinator


let root = URL(fileURLWithPath: CommandLine.input)

let availableCategoryIDs = [2,3,4,5,6,7,8,9,11,16,17,18,20,22,23,24,25,30,32,34,35,39,40,41,42,43,46,63,65,66,87,91,350001]

let iconIDs: Future<[Int: IconID]>
let invMetaGroups: Future<[Int: ObjectID<SDEInvMetaGroup>]>
//let metaTypes: Future<[Int: MetaType]>

let invCategories: Future<[Int: ObjectID<SDEInvCategory>]>
let invGroups: Future<[Int: ObjectID<SDEInvGroup>]>
let invTypes: Future<[Int: ObjectID<SDEInvType>]>
let invMarketGroups: Future<[Int: ObjectID<SDEInvMarketGroup>]>
let eveUnits: Future<[Int: ObjectID<SDEEveUnit>]>
let dgmAttributeCategories: Future<[Int: ObjectID<SDEDgmAttributeCategory>]>
let dgmAttributeTypes: Future<[Int: ObjectID<SDEDgmAttributeType>]>
let dgmEffects: Future<[Int: ObjectID<SDEDgmEffect>]>
let chrRaces: Future<[Int: ObjectID<SDEChrRace>]>
let chrFactions: Future<[Int: ObjectID<SDEChrFaction>]>
let chrAncestries: Future<[Int: ObjectID<SDEChrAncestry>]>
let chrBloodlines: Future<[Int: ObjectID<SDEChrBloodline>]>
let certMasteryLevels: Future<[ObjectID<SDECertMasteryLevel>]>
let invNames: Future<[Int: String]>

let universe: Future<[(String, [(Region, [(Constellation, [Future<SolarSystem>])])])]>
let mapUniverses: Future<[ObjectID<SDEMapUniverse>]>
let mapSolarSystems: Future<[Int: ObjectID<SDEMapSolarSystem>]>
let staStations: Future<[Int: ObjectID<SDEStaStation>]>
//let mapDenormalize: Future<[Int: ObjectID<SDEMapDenormalize>]>

let ramActivities: Future<[Int:ObjectID<SDERamActivity>]>
//let ramAssemblyLineTypes: Future<[Int:ObjectID<SDERamAssemblyLineType>]>

var eveIcons: [Int: ObjectID<SDEEveIcon>] = [:]
var typeIcons: [Int: ObjectID<SDEEveIcon>] = [:]
var nameIcons: [String: ObjectID<SDEEveIcon>] = [:]

let typesDogma: Future<[Int: TypeDogma]>

let typeAttributes: Future<[Int: [Int: TypeAttribute]]>
let unpublishedMetaGroup: ObjectID<SDEInvMetaGroup> = {
	var objectID: ObjectID<SDEInvMetaGroup>?
	mainContext.performAndWait {
		let metaGroup = SDEInvMetaGroup(context: mainContext)
		metaGroup.metaGroupID = 1001
        metaGroup.metaGroupName = LocalizedConstant.unpublished.localized
		objectID = .init(metaGroup)
	}
	return objectID!
}()
let defaultMetaGroupID: Int = 1

let operationQueue = OperationQueue()
var typeNames = [String: Int]()

do {
	iconIDs = operationQueue.detach {
		let from = Date(); defer {print("iconIDs\t\(Date().timeIntervalSince(from))s")}
		return try load(root.appendingPathComponent("/sde/fsd/iconIDs.json"))
	}
	
	_ = operationQueue.detach {
		let from = Date(); defer {print("extraIcons\t\(Date().timeIntervalSince(from))s")}
		try ["9_64_7", "105_32_32", "50_64_13", "38_16_193", "38_16_194", "38_16_195", "38_16_174", "17_128_4", "74_64_14", "23_64_3", "18_128_2", "33_128_2", "79_64_1", "79_64_2", "79_64_3", "79_64_4", "79_64_5", "79_64_6", "23_64_3"].forEach {
			if try SDEEveIcon.icon(iconName: $0) == nil {
				print("Warning: missing icon \($0)")
			}
		}
	}
	
	chrRaces = operationQueue.detach {
		let from = Date(); defer {print("chrRaces\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/races.json"), type: Schema.Races.self).map {($0.key, try .init(SDEChrRace($0)))})
	}
	
	chrFactions = operationQueue.detach {
		let from = Date(); defer {print("chrFactions\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/factions.json"), type: Schema.Factions.self).map {($0.key, try .init(SDEChrFaction($0)))})
	}

    chrAncestries = operationQueue.detach {
        let from = Date(); defer {print("chrAncestries\t\(Date().timeIntervalSince(from))s")}
        return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/ancestries.json"), type: Schema.Ancestries.self).map {($0.key, try .init(SDEChrAncestry($0)))})
    }

    chrBloodlines = operationQueue.detach {
        let from = Date(); defer {print("chrBloodlines\t\(Date().timeIntervalSince(from))s")}
        return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/bloodlines.json"), type: Schema.Bloodlines.self).map {($0.key, try .init(SDEChrBloodline($0)))})
    }

	invMetaGroups = operationQueue.detach {
		let from = Date(); defer {print("invMetaGroups\t\(Date().timeIntervalSince(from))s")}
        return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/metaGroups.json"), type: Schema.MetaGroups.self).map {($0.key, .init(SDEInvMetaGroup($0.key, $0.value)))})
	}
//	metaTypes = operationQueue.detach {
//		let from = Date(); defer {print("metaTypes\t\(Date().timeIntervalSince(from))s")}
//		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/invMetaTypes.json"), type: Schema.MetaTypes.self).map {($0.typeID, $0)})
//	}
	
	invCategories = operationQueue.detach {
		let from = Date(); defer {print("invCategories\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/categoryIDs.json"), type: Schema.CategoryIDs.self).filter{availableCategoryIDs.contains($0.key)}.map{($0.key, try .init(SDEInvCategory($0)))})
	}

	invGroups = operationQueue.detach {
		let from = Date(); defer {print("invGroups\t\(Date().timeIntervalSince(from))s")}
		let keys = try invCategories.get().keys
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/groupIDs.json"), type: Schema.GroupIDs.self).filter{keys.contains($0.value.categoryID)}.map{($0.key, try .init(SDEInvGroup($0)))})
	}
	
	invTypes = operationQueue.detach {
		let from = Date(); defer {print("invTypes\t\(Date().timeIntervalSince(from))s")}
		let keys = try invGroups.get().keys
		let typeIDs: Schema.TypeIDs = try load(root.appendingPathComponent("/sde/fsd/typeIDs.json"))
		
        let types: [Int: SDEInvType] = try Dictionary(uniqueKeysWithValues: typeIDs.filter{keys.contains($0.value.groupID)}.map{($0.key, try SDEInvType($0, typeIDs: typeIDs))})
        for (id, type) in typeIDs where type.variationParentTypeID != nil {
            types[id]?.parentType = types[type.variationParentTypeID!]
        }
        
        typeNames = Dictionary(typeIDs.filter{$0.value.name.en != nil}.map{($0.value.name.en!, $0.key)}, uniquingKeysWith: {a, _ in a})
        
        return types.mapValues{.init($0)}
	}
	
	invMarketGroups = operationQueue.detach {
		let from = Date(); defer {print("invMarketGroups\t\(Date().timeIntervalSince(from))s")}
		var invMarketGroups = [Int: SDEInvMarketGroup]()
        var queue = try load(root.appendingPathComponent("/sde/fsd/marketGroups.json"), type: Schema.MarketGroups.self).map{$0}
		while !queue.isEmpty {
			let first = queue.removeFirst()
            if let parentGroupID = first.value.parentGroupID {
				if let parent = invMarketGroups[parentGroupID] {
                    let marketGroup = try SDEInvMarketGroup(first.key, first.value)
					marketGroup.parentGroup = parent
					parent.addToSubGroups(marketGroup)
					invMarketGroups[first.key] = marketGroup
				}
				else {
					queue.append(first)
				}
			}
			else {
                let marketGroup = try SDEInvMarketGroup(first.key, first.value)
				invMarketGroups[first.key] = marketGroup
			}
		}
		return Dictionary(uniqueKeysWithValues: invMarketGroups.map {($0.key, .init($0.value))})
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
		try types.forEach { (_, objectID) in
			let type = try objectID.object()
			guard let attributes = type.attributes as? Set<SDEDgmTypeAttribute> else {return}
			
			for i in pairs {
				guard let skillID = attributes.first(where: {$0.attributeType?.attributeID == i.0}),
					let skillLevel = attributes.first(where: {$0.attributeType?.attributeID == i.1}),
					let skill = try types[Int(skillID.value)]?.object(),
					Int32(skillID.value) != type.typeID else {continue}
				let requiredSkill = SDEInvTypeRequiredSkill(context: .current)
				requiredSkill.type = type
				requiredSkill.skillType = skill
				requiredSkill.skillLevel = Int16(skillLevel.value)
				
			}
		}
	}
	
//	_ = operationQueue.detach {
//		let from = Date(); defer {print("parentTypes\t\(Date().timeIntervalSince(from))s")}
//		let types = try invTypes.get()
//		try metaTypes.get().forEach { (typeID, value) in
//			try types[typeID]?.object().parentType = types[value.parentTypeID]!.object()
//		}
//	}

	eveUnits = operationQueue.detach {
		let from = Date(); defer {print("eveUnits\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/eveUnits.json"), type: Schema.Units.self).map {($0.unitID, .init(SDEEveUnit($0)))})
	}
	
	dgmAttributeCategories = operationQueue.detach {
		let from = Date(); defer {print("dgmAttributeCategories\t\(Date().timeIntervalSince(from))s")}
        return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/dogmaAttributeCategories.json"), type: Schema.AttributeCategories.self).map {($0.key, .init(SDEDgmAttributeCategory($0.value, $0.key)))})
	}

	dgmAttributeTypes = operationQueue.detach {
		let from = Date(); defer {print("dgmAttributeTypes\t\(Date().timeIntervalSince(from))s")}
        return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/dogmaAttributes.json"), type: Schema.AttributeTypes.self).map {($0.key, .init(try SDEDgmAttributeType($0.value)))})
	}

	dgmEffects = operationQueue.detach {
		let from = Date(); defer {print("dgmEffects\t\(Date().timeIntervalSince(from))s")}
        return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/fsd/dogmaEffects.json"), type: Schema.Effects.self).map {($0.key, .init(SDEDgmEffect($0.value)))})
	}
    
    typesDogma = operationQueue.detach {
        let from = Date(); defer {print("typesDogma\t\(Date().timeIntervalSince(from))s")}
        return try load(root.appendingPathComponent("/sde/fsd/typeDogma.json"), type: Schema.TypesDogma.self)
    }

	typeAttributes = operationQueue.detach {
		let from = Date(); defer {print("typeAttributes\t\(Date().timeIntervalSince(from))s")}
        let typeAttributes = try typesDogma.get().map { (typeID, type) in
            (typeID, Dictionary(uniqueKeysWithValues: type.dogmaAttributes.map { i in (i.attributeID, TypeAttribute(attributeID: i.attributeID, typeID: typeID, valueInt: nil, valueFloat: i.value)) }))
        }
        return Dictionary(uniqueKeysWithValues: typeAttributes)
	}

	_ = operationQueue.detach {
		let from = Date(); defer {print("typeEffects\t\(Date().timeIntervalSince(from))s")}
		let types = try invTypes.get()
		let effects = try dgmEffects.get()
        let dogma = try typesDogma.get()
        
        for (typeID, type) in dogma {
            for effect in type.dogmaEffects {
                guard let effect = try effects[effect.effectID]?.object() else {return}
                try types[typeID]?.object().addToEffects(effect)
            }
        }
	}
	
	certMasteryLevels = operationQueue.detach {
		let from = Date(); defer {print("certMasteryLevels\t\(Date().timeIntervalSince(from))s")}
        return try zip([LocalizedConstant.basic.localized!,
                        LocalizedConstant.standard.localized!,
                        LocalizedConstant.improved.localized!,
                        LocalizedConstant.advanced.localized!,
                        LocalizedConstant.elite.localized!],
                       ["79_64_2", "79_64_3", "79_64_4", "79_64_5", "79_64_6"]).enumerated().map { (i, cert) in try .init(SDECertMasteryLevel(level: i, name: cert.0, iconName: cert.1))
		}
	}
	
	_ = operationQueue.detach {
		let from = Date(); defer {print("certCertificates\t\(Date().timeIntervalSince(from))s")}
		try load(root.appendingPathComponent("/sde/fsd/certificates.json"), type: Schema.Certificates.self).forEach {
			_ = try SDECertCertificate($0)
		}
	}
	
	invNames = operationQueue.detach {
		let from = Date(); defer {print("invNames\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/invNames.json"), type: Schema.Names.self).map {($0.itemID, $0.itemName ?? "\($0.itemID)")})
	}

	universe = operationQueue.detach {
		let from = Date(); defer {print("universe\t\(Date().timeIntervalSince(from))s")}
		let fileManager = FileManager.default
//		let universes = try load(root.appendingPathComponent("/sde/bsd/mapUniverse.json"), type: Schema.Universes.self)
		
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
		/*let from = Date(); defer {print("mapUniverses\t\(Date().timeIntervalSince(from))s")}
        let path = root.appendingPathComponent("/sde/fsd/universe")
		let fileManager = FileManager.default
        
        let universes = try fileManager.contentsOfDirectory(atPath: path.path)
            .filter { name in
                var isDir: ObjCBool = false
                fileManager.fileExists(atPath: path.appendingPathComponent(name).path, isDirectory: &isDir)
                return isDir.boolValue
            }
            .map { name in
            Universe(radius: 0, universeID: 0, universeName: name, x: 0, xMax: 0, xMin: 0, y: 0, yMax: 0, yMin: 0, z: 0, zMax: 0, zMin: 0)
        }
//		let universes = try load(root.appendingPathComponent("/sde/fsd/universe"), type: Schema.Universes.self)
//
//        root.appendPathComponent(<#T##pathComponent: String##String#>)*/
		
		return try universe.get().map {
			let universe = SDEMapUniverse(context: .current)
			switch $0.0 {
			case "wormhole":
                universe.name = $0.0.capitalized //universes.first {$0.universeID == 9000001}!.universeName
				universe.universeID = 9000001
			case "eve":
				universe.name = $0.0.capitalized//universes.first {$0.universeID == 9}!.universeName
				universe.universeID = 9
			case "abyssal":
				universe.name = $0.0.capitalized//"Abyssal"
				universe.universeID = 9100001
			case "penalty":
                universe.name = $0.0.capitalized//"Penalty"
				universe.universeID = 9100002
			default:
				throw DumpError.invalidUniverse($0.0)
			}

			try $0.1.forEach {
				let region = try SDEMapRegion($0.0)
				region.universe = universe
				try $0.1.forEach {
					let constellation = try SDEMapConstellation($0.0)
					constellation.region = region
					try $0.1.forEach {
						let solarSystem = try SDEMapSolarSystem($0.get())
						solarSystem.constellation = constellation
					}
					
					constellation.security = (constellation.solarSystems?.allObjects as? [SDEMapSolarSystem]).map { array in
						return !array.isEmpty ? array.map{$0.security}.reduce(0, +) / Float(array.count) : 0
					} ?? 0
				}
				
				if let array = (region.constellations?.allObjects as? [SDEMapConstellation])?.flatMap ({return $0.solarSystems?.allObjects as? [SDEMapSolarSystem] ?? []}), !array.isEmpty  {
					region.security = array.map {$0.security}.reduce(0, +) / Float(array.count)
				}
				else {
					region.security = 0
				}
				
				if region.regionID >= Int32(NCDBRegionID.whSpace.rawValue) {
					region.securityClass = -1
				}
				else {
					switch region.security {
					case 0.5...1:
						region.securityClass = 1
					case -1...0:
						region.securityClass = 0
					default:
						region.securityClass = 0.5
					}
				}

			}
			return .init(universe)
		}
	}

	mapSolarSystems = operationQueue.detach {
		let from = Date(); defer {print("mapSolarSystems\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues:
			mapUniverses.get().compactMap {
				try ($0.object().regions as! Set<SDEMapRegion>).map {
					($0.constellations as! Set<SDEMapConstellation>).map {
						($0.solarSystems as! Set<SDEMapSolarSystem>).map {(Int($0.solarSystemID), .init($0))}
						}.joined()
					}.joined()
				}.joined()
		)
	}

	staStations = operationQueue.detach {
		let from = Date(); defer {print("staStations\t\(Date().timeIntervalSince(from))s")}
		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/sde/bsd/staStations.json"), type: Schema.Stations.self).map {($0.stationID, try .init(SDEStaStation($0)))})
	}
	
	ramActivities = operationQueue.detach {
        let activities = try [
            SDERamActivity(0, LocalizedConstant.none.localized!, true, nil),
            SDERamActivity(1, LocalizedConstant.manufacturing.localized!, true, "18_02"),
            SDERamActivity(2, LocalizedConstant.researchingTechnology.localized!, false, "33_02"),
            SDERamActivity(3, LocalizedConstant.researchingTimeProductivity.localized!, true, "33_02"),
            SDERamActivity(4, LocalizedConstant.researchingMaterialProductivity.localized!, true, "33_02"),
            SDERamActivity(5, LocalizedConstant.copying.localized!, true, "33_02"),
            SDERamActivity(6, LocalizedConstant.duplicating.localized!, false, nil),
            SDERamActivity(7, LocalizedConstant.reverseEngineering.localized!, true, "33_02"),
            SDERamActivity(8, LocalizedConstant.invention.localized!, true, "33_02"),
            SDERamActivity(11,LocalizedConstant.unnamed.localized!, true, "18_02"),
        ]
        return Dictionary(uniqueKeysWithValues: activities.map{(Int($0.activityID), .init($0))})
	}

//	ramAssemblyLineTypes = operationQueue.detach {
//		let from = Date(); defer {print("ramAssemblyLineTypes\t\(Date().timeIntervalSince(from))s")}
//		return try Dictionary(uniqueKeysWithValues: load(root.appendingPathComponent("/ramAssemblyLineTypes.json"), type: Schema.AssemblyLineTypes.self).map {($0.assemblyLineTypeID, try .init(SDERamAssemblyLineType($0)))})
//	}

//	_ = operationQueue.detach {
//		let from = Date(); defer {print("ramInstallationTypeContents\t\(Date().timeIntervalSince(from))s")}
//		_ = try load(root.appendingPathComponent("/sde/bsd/ramInstallationTypeContents.json"), type: Schema.InstallationTypeContents.self).map {
//			try SDERamInstallationTypeContent($0)
//		}
//	}

	_ = operationQueue.detach {
		let from = Date(); defer {print("npcGroups\t\(Date().timeIntervalSince(from))s")}
		let url = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().appendingPathComponent("npc.json")
		
		_ = try JSONDecoder().decode([NPCGroup].self, from: Data(contentsOf: url)).map { try SDENpcGroup($0) }
	}
	
	_ = operationQueue.detach {
		let from = Date(); defer {print("indBlueprints\t\(Date().timeIntervalSince(from))s")}
		_ = try load(root.appendingPathComponent("/sde/fsd/blueprints.json"), type: Schema.Blueprints.self).compactMap {
			try SDEIndBlueprintType($0.value)
		}
	}
	
//	_ = operationQueue.detach {
//		let from = Date(); defer {print("whTypes\t\(Date().timeIntervalSince(from))s")}
//		try invTypes.get().values.filter {try $0.object().group!.groupID == 988}.map { try SDEWhType($0.object()) }
////		_ = try (invGroups.get()[988]!.object().types as! Set<SDEInvType>).map {
////			try SDEWhType($0)
////		}
//	}

	operationQueue.waitUntilAllOperationsAreFinished()
	try mainContext.save()
	
	_ = operationQueue.detach {
		let from = Date(); defer {print("dgmpp\t\(Date().timeIntervalSince(from))s")}
		try dgmpp()
	}


	/*mapDenormalize = operationQueue.detach {
		let from = Date(); defer {print("mapDenormalize\t\(Date().timeIntervalSince(from))s")}
		let stations = try Set(staStations.get().keys)
		let denormalize = try universe.get().map { try $0.1.map { try $0.1.map { try $0.1.map { solarSystem in
			try solarSystem.get().planets.values.map { planet -> [(Int, SDEMapDenormalize)] in
				let npcStations = planet.npcStations?.filter {!stations.contains($0.key)}.map {$0}
				let moonStations = planet.moons?.flatMap { $0.1.npcStations?.filter {!stations.contains($0.key)} }
				return try [moonStations?.joined().map{$0}, npcStations].flatMap{ $0 }.joined().map{ station in
					try (station.key, SDEMapDenormalize(station: station, solarSystem: solarSystem.get()))
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
	
	invGroups = try Dictionary(uniqueKeysWithValues: groupIDs.get().filter{invCategories.keys.contains($0.value.categoryID)}.map{($0.key, SDEInvGroup($0))})
	
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
	
//    print(allColors.sorted())
    
	print("Save...")
	try mainContext.save()

}
catch {
	print("\(error)")
}


