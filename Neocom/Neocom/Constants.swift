//
//  Constants.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

enum NCDBAttributeID: Int {
	case none = 0
	case charismaBonus = 175
	case intelligenceBonus = 176
	case memoryBonus = 177
	case perceptionBonus = 178
	case willpowerBonus = 179
	case primaryAttribute = 180
	case secondaryAttribute = 181
	case skillTimeConstant = 275
	
	case charisma = 164
	case intelligence = 165
	case memory = 166
	case perception = 167
	case willpower = 168
	
	case warpSpeedMultiplier = 600
	case baseWarpSpeed = 1281
	
	case kineticDamageResonance = 109
	case thermalDamageResonance = 110
	case explosiveDamageResonance = 111
	case emDamageResonance = 113
	case armorEmDamageResonance = 267
	case armorExplosiveDamageResonance = 268
	case armorKineticDamageResonance = 269
	case armorThermalDamageResonance = 270
	case shieldEmDamageResonance = 271
	case shieldExplosiveDamageResonance = 272
	case shieldKineticDamageResonance = 273
	case shieldThermalDamageResonance = 274
	
	case passiveShieldThermalDamageResonance = 1425
	case passiveShieldKineticDamageResonance = 1424
	case passiveShieldExplosiveDamageResonance = 1422
	case passiveShieldEmDamageResonance = 1423
	case hullThermalDamageResonance = 977
	case hullKineticDamageResonance = 976
	case hullExplosiveDamageResonance = 975
	case hullEmDamageResonance = 974
	case passiveArmorThermalDamageResonance = 1419
	case passiveArmorKineticDamageResonance = 1420
	case passiveArmorExplosiveDamageResonance = 1421
	case passiveArmorEmDamageResonance = 1418
	
	case emDamage = 114
	case explosiveDamage = 116
	case kineticDamage = 117
	case thermalDamage = 118
	
}

enum NCDBAttributeCategoryID: Int {
	case none = 0
	case fitting = 1
	case shield = 2
	case armor = 3
	case structure = 4
	case requiredSkills = 8
	case null = 9
}

enum NCDBUnitID: Int {
	case none = 0
	case milliseconds = 101
	case inverseAbsolutePercent = 108
	case modifierPercent = 109
	case inversedModifierPercent = 111
	case groupID = 115
	case typeID = 116
	case sizeClass = 117
	case attributeID = 119
	case fittingSlots = 122
	case absolutePercent = 127
	case boolean = 137
	case bonus = 139
}

enum NCDBCategoryID: Int {
	case ship = 6
	case blueprint = 9
	case skill = 16
}

enum NCDBRegionID: Int {
	case theForge = 10000002
	case whSpace = 11000000
}

extension NCDBEveIcon {
	enum File: String {
		case certificateUnclaimed = "79_01"
	}
}



extension Notification.Name {
	public static let NCCurrentAccountChanged = Notification.Name("NCCurrentAccountChanged")
	public static let NCMarketRegionChanged = Notification.Name("NCMarketRegionChanged")
}

let ESClientID = "c2cc974798d4485d966fba773a8f7ef8"
let ESSecretKey = "GNhSE9GJ6q3QiuPSTIJ8Q1J6on4ClM4v9zvc0Qzu"
let ESCallbackURL = URL(string: "neocom://sso")!

extension UserDefaults {
	struct Key {
		static let NCCurrentAccount = "NCCurrectAccount"
		static let NCMarketRegion = "NCMarketRegion"
	}
}
