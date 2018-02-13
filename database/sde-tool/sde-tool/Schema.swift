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
	struct Traits {
		struct RoleBonus: Codable {
			var bonus: Int?
			var bonusText: LocalizedString?
			var nameID: Int?
			var importance: Int
			var unitID: Int?
		}
		var roleBonuses: [RoleBonus]?
		var types: [Int: RoleBonus]?
		var miscBonuses: [RoleBonus]?
	}
	var description: LocalizedString?
	var groupID: Int
	var name: LocalizedString
	var portionSize: Int
	var published: Bool
	var graphicID: Int?
	var radius: Int?
	var soundID: Int?
	var mass: Double?
	var volume: Double?
	var basePrice: Double?
	var marketGroupID: Int?
	var raceID: Int?
	var masteries: [Int]?
	var factionID: Int?
	var capacity: Int?
	var sofFactionName: String?
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

enum Schema {
	typealias CategoryIDs = [Int: CategoryID]
	typealias GroupIDs = [Int: GroupID]
	typealias TypeIDs = [Int: TypeID]
	typealias Blueprints = [Int: Blueprint]
	typealias Certificates = [Int: Certificate]
	typealias IconIDs = [Int: IconID]
}
