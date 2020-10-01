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
    var ko: String?
    
    init(en: String?, de: String? = nil, es: String? = nil, fr: String? = nil, it: String? = nil, ja: String? = nil, ru: String? = nil, zh: String? = nil, ko: String? = nil) {
        self.en = en
        self.de = de ?? en
        self.es = es ?? en
        self.fr = fr ?? en
        self.it = it ?? en
        self.ja = ja ?? en
        self.ru = ru ?? en
        self.zh = zh ?? en
        self.ko = ko ?? en
    }
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
		struct Bonus: Codable {
			var bonus: Double?
			var bonusText: LocalizedString?
			var nameID: Int?
			var importance: Int
			var unitID: Int?
            var isPositive: Bool?
		}
		var roleBonuses: [Bonus]?
		var types: [Int: [Bonus]]?
		var miscBonuses: [Bonus]?
        var iconID: Int?
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
    var metaGroupID: Int?
    var variationParentTypeID: Int?
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
	var backgrounds: [String]?
	var foregrounds: [String]?
	var obsolete: Bool?
}

struct Ancestry: Codable {
//	var ancestryID: Int
    var nameID: LocalizedString
	var bloodlineID: Int
    var descriptionID: LocalizedString?
	var charisma: Int
	var intelligence: Int
	var memory: Int
	var perception: Int
	var willpower: Int
	var shortDescription: String
	var iconID: Int?
}

struct Bloodline: Codable {
//	var bloodlineID: Int
//	var bloodlineName: String
    var descriptionID: LocalizedString?
    var nameID: LocalizedString
	var charisma: Int
	var intelligence: Int
	var memory: Int
	var perception: Int
	var willpower: Int
//	var description: String
//	var femaleDescription: String
//	var maleDescription: String
//	var shortDescription: String
//	var shortFemaleDescription: String
//	var shortMaleDescription: String

	var corporationID: Int
	var iconID: Int?
	var shipTypeID: Int
	var raceID: Int
    var lastNames: [String]?
}

struct Faction: Codable {
	var corporationID: Int?
    var descriptionID: LocalizedString?
//	var factionID: Int
    var nameID: LocalizedString
	var iconID: Int?
	var militiaCorporationID: Int?
	var memberRaces: [Int]
	var sizeFactor: Double
	var solarSystemID: Int
//	var stationCount: Int
//	var stationSystemCount: Int
    var uniqueName: Bool
}

struct Race: Codable {
    var descriptionID: LocalizedString?
//	var raceID: Int
    var nameID: LocalizedString
	var iconID: Int?
    var skills: [Int: Int]?
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
    var descriptionID: LocalizedString?
	var hasTypes: Bool
	var iconID: Int?
//	var marketGroupID: Int
    var nameID: LocalizedString
	var parentGroupID: Int?
}

struct MetaGroup: Codable {
    var nameID: LocalizedString
    var iconID: Int?
    var iconSuffix: String?
//    var metaGroupNameID: Int?
    var descriptionID: LocalizedString?
}

//struct MetaType: Codable {
//	var metaGroupID: Int
//	var parentTypeID: Int
//	var typeID: Int
//}

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
	var activityName: String?
	var description: String?
	var iconNo: String?
	var published: Bool
    var descriptionID: Int
    var activityNameID: Int
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
	var baseCostMultiplier: Double?
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
//	var stationName: String
	var stationTypeID: Int
	var x: Double
	var y: Double
	var z: Double
}

struct Universe: Codable {
	var radius: Double
	var universeID: Int
	var universeName: String
	var x: Double
	var xMax: Double
	var xMin: Double
	var y: Double
	var yMax: Double
	var yMin: Double
	var z: Double
	var zMax: Double
	var zMin: Double
}

struct Region: Codable {
	var center: [Double]
	var descriptionID: Int?
	var factionID: Int?
	var max: [Double]
	var min: [Double]
	var nameID: Int
	var nebula: Int
	var regionID: Int
	var wormholeClassID: Int?
}

struct Constellation: Codable {
	var center: [Double]
	var max: [Double]
	var min: [Double]
	var nameID: Int
	var constellationID: Int
	var radius: Double
	var wormholeClassID: Int?
	var factionID: Int?
}

struct SolarSystem: Codable {
	struct Planet: Codable {
		struct Statistics: Codable {
			var density: Double
			var eccentricity: Double
			var escapeVelocity: Double
			var fragmented: Bool
			var life: Double
			var locked: Bool
			var massDust: Double
			var massGas: Double
			var orbitPeriod: Double
			var orbitRadius: Double
			var pressure: Double
			var radius: Double
			var rotationRate: Double
			var spectralClass: String
			var surfaceGravity: Double
			var temperature: Double
		}
		
		struct Attributes: Codable {
			var heightMap1: Double
			var heightMap2: Double
			var population: Bool
			var shaderPreset: Double
		}
		
		struct Moon: Codable {
			var position: [Double]
			var planetAttributes: Attributes
			var radius: Double
			var typeID: Int
			var statistics: Statistics?
			var npcStations: [Int: Station]?
			var moonNameID: Int?
		}
		
		struct AsteroidBelt: Codable {
			var asteroidBeltNameID: Int?
			var position: [Double]
			var statistics: Statistics?
			var typeID: Int?
		}
		
		struct Station: Codable {
			var graphicID: Int
			var isConquerable: Bool
			var operationID: Int
			var ownerID: Int
			var position: [Double]
			var reprocessingEfficiency: Double
			var reprocessingHangarFlag: Int
			var reprocessingStationsTake: Double
			var typeID: Int
			var useOperationName: Bool
		}

		var celestialIndex: Int
		var planetAttributes: Attributes
		var position: [Double]
		var radius: Double
		var typeID: Int
		var statistics: Statistics
		var moons: [Int: Moon]?
		var asteroidBelts: [Int: AsteroidBelt]?
		var npcStations: [Int: Station]?
		var planetNameID: Int?

	}
	
	struct Star: Codable {
		struct Statistics: Codable {
			var age: Double
			var life: Double
			var locked: Bool
			var luminosity: Double
			var radius: Double
			var spectralClass: String
			var temperature: Double
		}
		
		var id: Int
		var radius: Double
		var statistics: Statistics
		var typeID: Int
	}
	
	struct Stargate: Codable {
		var destination: Int
		var position: [Double]
		var typeID: Int
	}
	
	struct SecondarySun: Codable {
		var effectBeaconTypeID: Int
		var itemID: Int
		var position: [Double]
		var typeID: Int
	}
	
	var center: [Double]
	var max: [Double]
	var min: [Double]
	var corridor: Bool
	var fringe: Bool
	var hub: Bool
	var international: Bool
	var luminosity: Double
	var border: Bool
	var planets: [Int: Planet]
	var radius: Double
	var regional: Bool
	var security: Double
	var securityClass: String?
	var solarSystemID: Int
	var solarSystemNameID: Int
	var star: Star?
	var secondarySun: SecondarySun?
	var stargates: [Int: Stargate]
	var sunTypeID: Int?
	var wormholeClassID: Int?
	var visualEffect: String?
	var disallowedAnchorCategories: [Int]?
	var disallowedAnchorGroups: [Int]?
	var descriptionID: Int?
	var factionID: Int?
}

struct AttributeCategory: Codable {
	var categoryDescription: String?
	var categoryID: Int
	var categoryName: String?
}

struct AttributeType: Codable {
    var attributeID: Int
    var categoryID: Int?
    var dataType: String?
    var defaultValue: Double
    var description: String?
    var displayNameID: LocalizedString?
    var highIsGood: Bool
    var iconID: Int?
    var name: String
    var published: Bool
    var stackable: Bool
    var tooltipDescriptionID: LocalizedString?
    var tooltipTitleID: LocalizedString?
    var unitID: Int?
    var maxAttributeID: Int?
    var chargeRechargeTimeID: Int?
//	var attributeID: Int
//	var attributeName: String
//	var categoryID: Int?
//	var defaultValue: Double
//	var description: String
//	var highIsGood: Bool
//	var published: Bool
//	var stackable: Bool
//	var iconID: Int?
//	var unitID: Int?
//	var displayName: String?
}

struct TypeAttribute: Codable {
	var attributeID: Int
	var typeID: Int
//	var value: Double?
	var valueInt: Int?
	var valueFloat: Double?
    var value: Double? {
        valueFloat ?? valueInt.map{Double($0)}
    }
}

struct Effect: Codable {
	var descriptionID: LocalizedString?
	var disallowAutoRepeat: Bool
	var dischargeAttributeID: Int?
	var displayNameID: LocalizedString?
	var distribution: String?
	var durationAttributeID: Int?
	var effectCategory: String
	var effectID: Int
	var effectName: String
	var electronicChance: Bool
	var guid: String?
	var isAssistance: Bool
	var isOffensive: Bool
	var isWarpSafe: Bool
	var postExpression: Int?
	var preExpression: Int?
	var propulsionChance: Bool
	var published: Bool
	var rangeChance: Bool
	var rangeAttributeID: Int?
	var sfxName: String?
	var iconID: Int?
	var falloffAttributeID: Int?
	var fittingUsageChanceAttributeID: Int?
	var npcActivationChanceAttributeID: Int?
    var resistanceAttributeID: Int?
    var npcUsageChanceAttributeID: Int?
    var trackingSpeedAttributeID: Int?
    var modifierInfo: [Modifier]?
    
    struct Modifier: Codable {
        var domain: String
        var `func`: String
        var modifiedAttributeID: Int?
        var modifyingAttributeID: Int?
        var operation: String?
        var skillTypeID: Int?
        var groupID: Int?
        var domainID: Int?
        var effectID: Int?
    }
}

struct TypeEffect: Codable {
	var effectID: Int
	var isDefault: Bool
	var typeID: Int

}

struct NPCGroup: Codable {
	var groupName: String
	var iconName: String?
	var groupID: Int?
	var groups: [NPCGroup]?
}

struct TypeDogma: Codable {
    struct Attribute: Codable {
        var attributeID: Int
        var value: Double
    }
    struct Effect: Codable {
        var effectID: Int
        var isDefault: Bool
    }
    
    var dogmaAttributes: [Attribute]
    var dogmaEffects: [Effect]
}

enum Schema {
	typealias CategoryIDs = [Int: CategoryID]
	typealias GroupIDs = [Int: GroupID]
	typealias TypeIDs = [Int: TypeID]
	typealias Blueprints = [Int: Blueprint]
	typealias Certificates = [Int: Certificate]
	typealias IconIDs = [Int: IconID]
    typealias Ancestries = [Int: Ancestry]
    typealias Bloodlines = [Int: Bloodline]
    typealias Factions = [Int: Faction]
    typealias Races = [Int: Race]
	typealias Units = [Unit]
	typealias Flags = [Flag]
	typealias Items = [Item]
    typealias MarketGroups = [Int: MarketGroup]
    typealias MetaGroups = [Int: MetaGroup]
//	typealias MetaTypes = [MetaType]
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
	typealias AttributeCategories = [AttributeCategory]
    typealias AttributeTypes = [Int: AttributeType]
//	typealias TypeAttributes = [TypeAttribute]
    typealias Effects = [Int: Effect]
//	typealias TypeEffects = [TypeEffect]
	typealias Universes = [Universe]
    typealias TypesDogma = [Int: TypeDogma]
}

