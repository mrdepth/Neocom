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
	
	case signatureRadius = 552
	
	case missileLaunchDuration = 506
	case entityMissileTypeID = 507
	case maxVelocity = 37
	case speed = 51
	case maxRange = 54
	case falloff = 158
	case trackingSpeed = 160
	case damageMultiplier = 64
	case agility = 70
	case explosionDelay = 281
	case missileDamageMultiplier = 212
	case missileEntityVelocityMultiplier = 645
	case missileEntityFlightTimeMultiplier = 646
	case shieldRechargeRate = 479
	case shieldCapacity = 263
	
	case entityShieldBoostDuration = 636
	case entityShieldBoostAmount = 637
	case entityArmorRepairDuration = 630
	case entityArmorRepairAmount = 631
	
	case entityShieldBoostDelayChance = 639
	case entityShieldBoostDelayChanceSmall = 1006
	case entityShieldBoostDelayChanceMedium = 1007
	case entityShieldBoostDelayChanceLarge = 1008
	case entityArmorRepairDelayChance = 638
	case entityArmorRepairDelayChanceSmall = 1009
	case entityArmorRepairDelayChanceMedium = 1010
	case entityArmorRepairDelayChanceLarge = 1011
}

enum NCDBAttributeCategoryID: Int {
	case none = 0
	case fitting = 1
	case shield = 2
	case armor = 3
	case structure = 4
	case requiredSkills = 8
	case null = 9
	case turrets = 29
	case missile = 30
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
	case module = 7
	case charge = 8
	case blueprint = 9
	case skill = 16
	case drone = 18
	case subsystem = 32
	case fighter = 87
	case structure = 65
	
	case asteroid = 25
	case ancientRelic = 34
	case material = 4
	case planetaryResource = 42
	case reaction = 24
	case entity = 11

}

enum NCDBRegionID: Int {
	case theForge = 10000002
	case whSpace = 11000000
}

enum NCDBDgmppItemCategoryID: Int {
	case none = 0
	case hi
	case med
	case low
	case rig
	case subsystem
	case mode
	case charge
	case drone
	case implant
	case booster
	case ship
	case structure
	case service
	case structureDrone
	case structureRig
}

enum NCDBEffectID: Int {
	case missileLaunchingForEntity = 569
}

extension NCDBEveIcon {
	enum File: String {
		case certificateUnclaimed = "79_01"
	}
}



extension Notification.Name {
	public static let NCCurrentAccountChanged = Notification.Name("NCCurrentAccountChanged")
	public static let NCMarketRegionChanged = Notification.Name("NCMarketRegionChanged")
	public static let NCCharacterChanged = Notification.Name("NCCharacterChanged")
}

let ESClientID = "a0cc80b7006944249313dc22205ec645"
let ESSecretKey = "deUqMep7TONp68beUoC1c71oabAdKQOJdbiKpPcC"
let ESCallbackURL = URL(string: "eveauthnc://sso/")!

let NCURLScheme = "neocom"

extension UserDefaults {
	struct Key {
		static let NCCurrentAccount = "NCCurrectAccount"
		static let NCMarketRegion = "NCMarketRegion"
	}
}

enum NCCellIdentifier {
	case `default`
	case action
}
