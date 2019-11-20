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
	
	struct Augmentations {
		var intelligence: Int = 0
		var memory: Int = 0
		var perception: Int = 0
		var willpower: Int = 0
		var charisma: Int = 0
	}
	
	var augmentations = Augmentations() {
		didSet {
			intelligence += augmentations.intelligence - oldValue.intelligence
			memory += augmentations.memory - oldValue.memory
			perception += augmentations.perception - oldValue.perception
			willpower += augmentations.willpower - oldValue.willpower
			charisma += augmentations.charisma - oldValue.charisma
		}
	}
	
	init() {
	}
	
	init(attributes: ESI.Skills.CharacterAttributes, implants: [Int]?) {
		self.intelligence = attributes.intelligence
		self.memory = attributes.memory
		self.perception = attributes.perception
		self.willpower = attributes.willpower
		self.charisma = attributes.charisma
		
		var augmentations = Augmentations()
		
		if let implants = implants {
			NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
				let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
				for implant in implants {
					if let attributes = invTypes[implant]?.allAttributes {
						if let value = attributes[NCDBAttributeID.intelligenceBonus.rawValue]?.value, value > 0 {
							augmentations.intelligence += Int(value)
						}
						if let value = attributes[NCDBAttributeID.memoryBonus.rawValue]?.value, value > 0 {
							augmentations.memory += Int(value)
						}
						if let value = attributes[NCDBAttributeID.perceptionBonus.rawValue]?.value, value > 0 {
							augmentations.perception += Int(value)
						}
						if let value = attributes[NCDBAttributeID.willpowerBonus.rawValue]?.value, value > 0 {
							augmentations.willpower += Int(value)
						}
						if let value = attributes[NCDBAttributeID.charismaBonus.rawValue]?.value, value > 0 {
							augmentations.charisma += Int(value)
						}
					}
				}
			})
		}
		
		self.augmentations = augmentations
	}
	
	/*init(clones: EVE.Char.Clones) {
		self.intelligence = clones.attributes.intelligence
		self.memory = clones.attributes.memory
		self.perception = clones.attributes.perception
		self.willpower = clones.attributes.willpower
		self.charisma = clones.attributes.charisma
		
		var augmentations = Augmentations()
		
		NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
			let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
			for implant in clones.implants ?? [] {
				if let attributes = invTypes[implant.typeID]?.allAttributes {
					if let value = attributes[NCDBAttributeID.intelligenceBonus.rawValue]?.value, value > 0 {
						augmentations.intelligence += Int(value)
					}
					if let value = attributes[NCDBAttributeID.memoryBonus.rawValue]?.value, value > 0 {
						augmentations.memory += Int(value)
					}
					if let value = attributes[NCDBAttributeID.perceptionBonus.rawValue]?.value, value > 0 {
						augmentations.perception += Int(value)
					}
					if let value = attributes[NCDBAttributeID.willpowerBonus.rawValue]?.value, value > 0 {
						augmentations.willpower += Int(value)
					}
					if let value = attributes[NCDBAttributeID.charismaBonus.rawValue]?.value, value > 0 {
						augmentations.charisma += Int(value)
					}
				}
			}
		})
		self.augmentations = augmentations
		intelligence += augmentations.intelligence
		memory += augmentations.memory
		perception += augmentations.perception
		willpower += augmentations.willpower
		charisma += augmentations.charisma

	}*/
	
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
	
	struct SkillKey: Hashable {
		let primary: NCDBAttributeID
		let secondary: NCDBAttributeID
		
		public var hashValue: Int {
			return (primary.rawValue << 16) + secondary.rawValue
		}
		
		public static func ==(lhs: SkillKey, rhs: SkillKey) -> Bool {
			return lhs.primary == rhs.primary && lhs.secondary == rhs.secondary
		}
	}

	
	class func optimal(for trainingQueue: NCTrainingQueue) -> NCCharacterAttributes? {
		var skillPoints: [SkillKey: Int] = [:]
		for skill in trainingQueue.skills {
			let sp = skill.skill.skillPointsToLevelUp
			let key = SkillKey(primary: skill.skill.primaryAttributeID, secondary: skill.skill.secondaryAttributeID)
			skillPoints[key] = (skillPoints[key] ?? 0) + sp
		}
		
		let basePoints = 17
		let bonusPoints = 14
		let maxPoints = 27
		let totalMaxPoints = basePoints * 5 + bonusPoints
		var minTrainingTime = TimeInterval.greatestFiniteMagnitude
		
		var optimal: [NCDBAttributeID: Int]?

		for intelligence in basePoints...maxPoints {
			for memory in basePoints...maxPoints {
				for perception in basePoints...maxPoints {
					guard intelligence + memory + perception < totalMaxPoints - basePoints * 2 else {break}
					for willpower in basePoints...maxPoints {
						guard intelligence + memory + perception + willpower < totalMaxPoints - basePoints else {break}
						let charisma = totalMaxPoints - (intelligence + memory + perception + willpower)
						guard charisma <= maxPoints else {continue}
						
						let attributes = [NCDBAttributeID.intelligence: intelligence,
						                  NCDBAttributeID.memory: memory,
						                  NCDBAttributeID.perception: perception,
						                  NCDBAttributeID.willpower: willpower,
						                  NCDBAttributeID.charisma: charisma]
						
						let trainingTime = skillPoints.reduce(0) { (t, i) -> TimeInterval in
							let primary = attributes[i.key.primary]!
							let secondary = attributes[i.key.secondary]!
							
							return t + TimeInterval(i.value) / (TimeInterval(primary) + TimeInterval(secondary) / 2)
						}
						
						
						if trainingTime < minTrainingTime {
							minTrainingTime = trainingTime
							optimal = attributes
						}
					}
				}
			}
		}
		if let optimal = optimal {
			let attributes = NCCharacterAttributes()
			attributes.intelligence = optimal[.intelligence]!
			attributes.memory = optimal[.memory]!
			attributes.perception = optimal[.perception]!
			attributes.willpower = optimal[.willpower]!
			attributes.charisma = optimal[.charisma]!
			return attributes
		}
		else {
			return nil
		}
	}
}
