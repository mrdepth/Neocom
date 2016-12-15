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
}

enum NCDBAttributeCategoryID: Int {
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
	case absolutePercent = 127
	case boolean = 137
	case bonus = 139
	
}

enum NCDBCategoryID: Int {
	case skills = 16
}
extension Notification.Name {
	public static let NCCurrentAccountChanged = Notification.Name("NCCurrentAccountChanged")
}

let ESClientID = "c2cc974798d4485d966fba773a8f7ef8"
let ESSecretKey = "GNhSE9GJ6q3QiuPSTIJ8Q1J6on4ClM4v9zvc0Qzu"
let ESCallbackURL = URL(string: "neocom://sso")!

extension UserDefaults {
	struct Key {
		static let NCCurrentAccount = "NCCurrectAccount"
	}
}
