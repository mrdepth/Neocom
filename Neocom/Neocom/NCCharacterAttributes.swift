//
//  NCCharacterAttributes.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class NCCharacterAttributes {
	var intelligence: Int = 20
	var memory: Int = 20
	var perception: Int = 20
	var willpower: Int = 20
	var charisma: Int = 19
	
	init() {
	}
	
	init(characterSheet: EVECharacterSheet) {
		NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
			let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
			for implant in characterSheet.implants {
				if let attributes = invTypes[implant.typeID]?.allAttributes {
					self.intelligence += Int(attributes[NCDBAttributeID.intelligenceBonus.rawValue]?.value ?? 0)
					self.memory += Int(attributes[NCDBAttributeID.memoryBonus.rawValue]?.value ?? 0)
					self.perception += Int(attributes[NCDBAttributeID.perceptionBonus.rawValue]?.value ?? 0)
					self.willpower += Int(attributes[NCDBAttributeID.willpowerBonus.rawValue]?.value ?? 0)
					self.charisma += Int(attributes[NCDBAttributeID.charismaBonus.rawValue]?.value ?? 0)
				}
			}
		})
	}
	
	func skillpointsPerSecond(forSkill skill: NCSkill) -> Double {
		return skillpointsPerSecond(primaryAttributeID: skill.primaryAttributeID, secondaryAttribute: skill.secondaryAttributeID)
	}
	
	func skillpointsPerSecond(primaryAttributeID: NCDBAttributeID, secondaryAttribute: NCDBAttributeID) -> Double {
		let effectivePrimaryAttribute = effectiveAttributeValue(attributeID: primaryAttributeID)
		let effectiveSecondaryAttribute = effectiveAttributeValue(attributeID: secondaryAttribute)
		return (Double(effectivePrimaryAttribute) + Double(effectiveSecondaryAttribute) / 2.0) / 60.0;

	}
	
	func effectiveAttributeValue(attributeID: NCDBAttributeID) -> Int {
		switch attributeID {
		case .intelligence:
			return intelligence
		case .memory:
			return memory
		case .perception:
			return perception
		case .willpower:
			return willpower
		case .charisma:
			return charisma
		default:
			return 0
		}
	}
}
