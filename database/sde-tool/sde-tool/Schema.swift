//
//  Schema.swift
//  sde-tool
//
//  Created by Artem Shimanski on 13.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

struct LocalizedString: Codable {
	var de: String?
	var en: String?
	var es: String?
	var fr: String?
	var it: String?
	var ja: String?
	var ru: String?
	var zh: String?
}

struct CategoryID: Codable {
	var published: Bool
	var name: LocalizedString
	var iconID: Int?
}

struct GroupID: Codable {
	var published: Bool
	var name: LocalizedString
	var iconID: Int?
	var anchorable: Bool
	var anchored: Bool
	var categoryID: Int
	var fittableNonSingleton: Bool
	var useBasePrice: Bool
}

struct TypeID: Codable {
	struct Traits: Codable {
		struct RoleBonus: Codable {
			var bonus: Double?
			var bonusText: LocalizedString?
			var nameID: Int?
			var importance: Int
			var unitID: Int?
		}
		var roleBonuses: [RoleBonus]?
		var types: [Int: [RoleBonus]]?
		var miscBonuses: [RoleBonus]?
	}
	var description: LocalizedString?
	var groupID: Int
	var name: LocalizedString
	var portionSize: Int
	var published: Bool
	var graphicID: Int?
	var radius: Double?
	var soundID: Int?
	var mass: Double?
	var volume: Double?
	var basePrice: Double?
	var marketGroupID: Int?
	var raceID: Int?
	var masteries: [Int: [Int]]?
	var factionID: Int?
	var capacity: Double?
	var sofFactionName: String?
	var sofMaterialSetID: Int?
	var iconID: Int?
	var traits: Traits?
}

struct Blueprint: Codable {
	struct Activities: Codable {
		struct Activity: Codable {
			struct Material: Codable {
				var quantity: Int
				var typeID: Int
			}
			struct Product: Codable {
				var quantity: Int
				var typeID: Int
				var probability: Double?
			}
			struct Skill: Codable {
				var level: Int
				var typeID: Int
			}
			var materials: [Material]?
			var products: [Product]?
			var skills: [Skill]?
			var time: Double
		}
		
		var copying: Activity?
		var invention: Activity?
		var manufacturing: Activity?
		var research_material: Activity?
		var research_time: Activity?
		var reaction: Activity?
	}
	var activities: Activities
	var blueprintTypeID: Int
	var maxProductionLimit: Int
}

struct Certificate: Codable {
	struct Skill: Codable {
		var advanced: Int
		var basic: Int
		var elite: Int
		var improved: Int
		var standard: Int
	}
	var description: String
	var groupID: Int
	var name: String
	var recommendedFor: [Int]?
	var skillTypes: [Int: Skill]
}

struct IconID: Codable {
	var description: String?
	var iconFile: String
}

struct Ancestry: Codable {
	var ancestryID: Int
	var ancestryName: String
	var bloodlineID: Int
	var description: String
	var charisma: Int
	var intelligence: Int
	var memory: Int
	var perception: Int
	var willpower: Int
	var shortDescription: String
	var iconID: Int?
}

struct Bloodline: Codable {
	var bloodlineID: Int
	var bloodlineName: String
	var charisma: Int
	var intelligence: Int
	var memory: Int
	var perception: Int
	var willpower: Int
	var description: String
	var femaleDescription: String
	var maleDescription: String
	var shortDescription: String
	var shortFemaleDescription: String
	var shortMaleDescription: String

	var corporationID: Int
	var iconID: Int?
	var shipTypeID: Int
	var raceID: Int
}

struct Faction: Codable {
	var corporationID: Int
	var description: String
	var factionID: Int
	var factionName: String
	var iconID: Int?
	var militiaCorporationID: Int?
	var raceIDs: Int
	var sizeFactor: Double
	var solarSystemID: Int
	var stationCount: Int
	var stationSystemCount: Int
}

struct Race: Codable {
	var description: String?
	var raceID: Int
	var raceName: String
	var shortDescription: String?
	var iconID: Int?
}

struct Unit: Codable {
	var description: String?
	var displayName: String?
	var unitID: Int
	var unitName: String
}

struct Flag: Codable {
	var flagID: Int
	var flagName: String
	var flagText: String
	var orderID: Int
}

struct Item: Codable {
	var flagID: Int
	var itemID: Int
	var locationID: Int
	var ownerID: Int
	var quantity: Int
	var typeID: Int
}

struct MarketGroup: Codable {
	var description: String?
	var hasTypes: Bool
	var iconID: Int?
	var marketGroupID: Int
	var marketGroupName: String
	var parentGroupID: Int?
}

struct MetaGroup: Codable {
	var metaGroupID: Int
	var metaGroupName: String
	var description: String?
}

struct MetaType: Codable {
	var metaGroupID: Int
	var parentTypeID: Int
	var typeID: Int
}

struct Name: Codable {
	var itemID: Int
	var itemName: String
}

struct TypeMaterial: Codable {
	var materialTypeID: Int
	var quantity: Int
	var typeID: Int
}

struct TypeReaction: Codable {
	var input: Bool
	var quantity: Int
	var reactionTypeID: Int
	var typeID: Int
}

struct PlanetSchematic: Codable {
	var cycleTime: Int
	var schematicID: Int
	var schematicName: String
}

struct PlanetSchematicsPinMap: Codable {
	var pinTypeID: Int
	var schematicID: Int
}

struct PlanetSchematicsTypeMap: Codable {
	var isInput: Bool
	var quantity: Int
	var schematicID: Int
	var typeID: Int
}

struct Activity: Codable {
	var activityID: Int
	var activityName: String
	var description: String
	var iconNo: String?
	var published: Bool
}

struct AssemblyLineStation: Codable {
	var assemblyLineTypeID: Int
	var ownerID: Int
	var quantity: Int
	var regionID: Int
	var solarSystemID: Int
	var stationID: Int
	var stationTypeID: Int
}

struct AssemblyLineTypeDetailPerCategory: Codable {
	var assemblyLineTypeID: Int
	var categoryID: Int
	var costMultiplier: Double
	var materialMultiplier: Double
	var timeMultiplier: Double
}

struct AssemblyLineTypeDetailPerGroup: Codable {
	var assemblyLineTypeID: Int
	var groupID: Int
	var costMultiplier: Double
	var materialMultiplier: Double
	var timeMultiplier: Double
}

struct AssemblyLineType: Codable {
	var activityID: Int
	var assemblyLineTypeID: Int
	var assemblyLineTypeName: String
	var baseCostMultiplier: Double
	var baseMaterialMultiplier: Double
	var baseTimeMultiplier: Double
	var description: String
	var volume: Double
	var minCostPerHour: Double?
}

struct InstallationTypeContent: Codable {
	var assemblyLineTypeID: Int
	var installationTypeID: Int
	var quantity: Int
}

struct Station: Codable {
	var constellationID: Int
	var corporationID: Int
	var dockingCostPerVolume: Double
	var maxShipVolumeDockable: Int
	var officeRentalCost: Double
	var operationID: Int
	var regionID: Int
	var reprocessingEfficiency: Double
	var reprocessingHangarFlag: Int
	var reprocessingStationsTake: Double
	var security: Double
	var solarSystemID: Int
	var stationID: Int
	var stationName: String
	var stationTypeID: Int
	var x: Double
	var y: Double
	var z: Double
}

enum Schema {
	typealias CategoryIDs = [Int: CategoryID]
	typealias GroupIDs = [Int: GroupID]
	typealias TypeIDs = [Int: TypeID]
	typealias Blueprints = [Int: Blueprint]
	typealias Certificates = [Int: Certificate]
	typealias IconIDs = [Int: IconID]
	typealias Ancestries = [Ancestry]
	typealias Bloodlines = [Bloodline]
	typealias Factions = [Faction]
	typealias Races = [Race]
	typealias Units = [Unit]
	typealias Flags = [Flag]
	typealias Items = [Item]
	typealias MarketGroups = [MarketGroup]
	typealias MetaGroups = [MetaGroup]
	typealias MetaTypes = [MetaType]
	typealias Names = [Name]
	typealias TypeMaterials = [TypeMaterial]
	typealias TypeReactions = [TypeReaction]
	typealias PlanetSchematics = [PlanetSchematic]
	typealias PlanetSchematicsPinMaps = [PlanetSchematicsPinMap]
	typealias PlanetSchematicsTypeMaps = [PlanetSchematicsTypeMap]
	typealias Activities = [Activity]
	typealias AssemblyLineStations = [AssemblyLineStation]
	typealias AssemblyLineTypeDetailPerCategories = [AssemblyLineTypeDetailPerCategory]
	typealias AssemblyLineTypeDetailPerGroups = [AssemblyLineTypeDetailPerGroup]
	typealias AssemblyLineTypes = [AssemblyLineType]
	typealias InstallationTypeContents = [InstallationTypeContent]
	typealias Stations = [Station]
}
