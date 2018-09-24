//
//  Character.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

struct Character: Codable {
	struct Skill: Hashable, Codable {
		let typeID: Int
		let primaryAttributeID: SDEAttributeID
		let secondaryAttributeID: SDEAttributeID
		let rank: Double
	}
	
	struct Attributes: Codable {
		var intelligence: Int
		var memory: Int
		var perception: Int
		var willpower: Int
		var charisma: Int
	}
	
//	struct TrainedSkill: Codable {
//		var skill: Skill
//		var characterSkill: ESI.Skills.CharacterSkills.Skill
//	}
	
	struct SkillQueueItem: Codable {
		var skill: Skill
		var queuedSkill: ESI.Skills.SkillQueueItem
	}
	
	var attributes: Attributes
	var augmentations: Attributes
	var trainedSkills: [Int: ESI.Skills.CharacterSkills.Skill]
	var skillQueue: [SkillQueueItem]
	
	
	static let empty = Character(attributes: .default, augmentations: .none, trainedSkills: [:], skillQueue: [])
	
//	init(attributes: ESI.Skills.CharacterAttributes, skills: ESI.Skills.CharacterSkills, skillQueue: [ESI.Skills.SkillQueueItem]) {
//		
//	}
}


extension Character.Skill {
	init?(type: SDEInvType) {
		guard let primaryAttributeID = type[.primaryAttribute].flatMap({SDEAttributeID(rawValue: Int32($0.value))}),
			let secondaryAttributeID = type[.secondaryAttribute].flatMap({SDEAttributeID(rawValue: Int32($0.value))}),
			let rank = type[.skillTimeConstant]?.value else { return nil }
		typeID = Int(type.typeID)
		self.primaryAttributeID = primaryAttributeID
		self.secondaryAttributeID = secondaryAttributeID
		self.rank = rank
	}
	
	func skillPoints(at level: Int) -> Int {
		if (level == 0 || rank == 0) {
			return 0
		}
		let sp = pow(2, 2.5 * Double(level) - 2.5) * 250.0 * Double(rank)
		return Int(sp.rounded(.up))
	}
	
	func level(with skillpoints: Int) -> Int {
		if (skillpoints == 0 || rank == 0) {
			return 0
		}
		let level = (log(Double(skillpoints)/(250.0 * Double(rank))) / log(2.0) + 2.5) / 2.5;
		return Int(level.rounded(.down))
	}
	
	func skillpointsPerSecond(with attributes: Character.Attributes) -> Double {
		let primary = attributes[primaryAttributeID]
		let secondary = attributes[secondaryAttributeID]
		return (Double(primary) + Double(secondary) / 2.0) / 60.0;
	}
}

extension Character.Attributes {
	static let `default` = Character.Attributes(intelligence: 20, memory: 20, perception: 20, willpower: 20, charisma: 19)
	static let none = Character.Attributes(intelligence: 0, memory: 0, perception: 0, willpower: 0, charisma: 0)
	
	subscript(key: SDEAttributeID) -> Int {
		get {
			switch key {
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
		set {
			switch key {
			case .intelligence:
				intelligence = newValue
			case .memory:
				memory = newValue
			case .perception:
				perception = newValue
			case .willpower:
				willpower = newValue
			case .charisma:
				charisma = newValue
			default:
				break
			}
		}
	}
	
	static func + (lhs: Character.Attributes, rhs: Character.Attributes) -> Character.Attributes {
		var lhs = lhs
		lhs.charisma += rhs.charisma
		lhs.intelligence += rhs.intelligence
		lhs.perception += rhs.perception
		lhs.willpower += rhs.willpower
		lhs.charisma += rhs.charisma
		return lhs
	}
	
	static func - (lhs: Character.Attributes, rhs: Character.Attributes) -> Character.Attributes {
		var lhs = lhs
		lhs.charisma -= rhs.charisma
		lhs.intelligence -= rhs.intelligence
		lhs.perception -= rhs.perception
		lhs.willpower -= rhs.willpower
		lhs.charisma -= rhs.charisma
		return lhs
	}
	
	static func += (lhs: inout Character.Attributes, rhs: Character.Attributes) {
		lhs.charisma += rhs.charisma
		lhs.intelligence += rhs.intelligence
		lhs.perception += rhs.perception
		lhs.willpower += rhs.willpower
		lhs.charisma += rhs.charisma
	}
	
	static func -= (lhs: inout Character.Attributes, rhs: Character.Attributes) {
		lhs.charisma -= rhs.charisma
		lhs.intelligence -= rhs.intelligence
		lhs.perception -= rhs.perception
		lhs.willpower -= rhs.willpower
		lhs.charisma -= rhs.charisma
	}
}

extension Character.SkillQueueItem {
	var skillPoints: Int {
		
		if let startDate = queuedSkill.startDate,
			let finishDate = queuedSkill.finishDate,
			let trainingStartSP = queuedSkill.trainingStartSP,
			let levelEndSP = queuedSkill.levelEndSP,
			finishDate > Date() {
			let t = finishDate.timeIntervalSince(startDate)
			if t > 0 {
				let spps = Double(levelEndSP - trainingStartSP) / t
				let t = finishDate.timeIntervalSinceNow
				let sp = Int(t > 0 ? Double(levelEndSP) - t * spps : Double(levelEndSP))
				return max(sp, trainingStartSP);
			}
			else {
				return levelEndSP
			}
		}
		return skill.skillPoints(at: max(queuedSkill.finishedLevel - 1, 0))
	}
	
//	func trainingTime(to level: Int, with attributes: Character.Attributes) -> TimeInterval {
//		return (Double(skill.skillPoints(at: level) - skillPoints)) / skill.skillpointsPerSecond(with: attributes)
//	}

	func trainingTimeToLevelUp(with attributes: Character.Attributes) -> TimeInterval {
		return Double(skillPointsToLevelUp) / skill.skillpointsPerSecond(with: attributes)
//		return trainingTime(to: queuedSkill.finishedLevel, with: attributes)
	}
	
	var skillPointsToLevelUp: Int {
		return skill.skillPoints(at: queuedSkill.finishedLevel) - skillPoints
	}

	var isActive: Bool {
		let date = Date()
		if let startDate = queuedSkill.startDate,
			let finishDate = queuedSkill.finishDate,
			finishDate > date && startDate < date {
			return true
		}
		else {
			return false
		}
	}
	
	var trainingProgress: Float {
		let level = queuedSkill.finishedLevel
		guard level > 0 else {return 0}
		
		let start = Double(skill.skillPoints(at: level - 1))
		let end = Double(skill.skillPoints(at: level))
		let left = Double(skillPointsToLevelUp)
		let progress = (1.0 - left / (end - start)).clamped(to: 0...1);
		return Float(progress)
	}
}


extension Character.Attributes {
	struct Key: Hashable {
		let primary: SDEAttributeID
		let secondary: SDEAttributeID
	}
	
	init(optimalFor trainingQueue: TrainingQueue) {
		var skillPoints: [Key: Int] = [:]
		for item in trainingQueue.queue {
			let sp = item.finishSP - item.startSP
			let key = Key(primary: item.skill.primaryAttributeID, secondary: item.skill.secondaryAttributeID)
			skillPoints[key, default: 0] += sp
		}
		
		let basePoints = 17
		let bonusPoints = 14
		let maxPoints = 27
		let totalMaxPoints = basePoints * 5 + bonusPoints
		var minTrainingTime = TimeInterval.greatestFiniteMagnitude
		
		var optimal = Character.Attributes.default
		
		for intelligence in basePoints...maxPoints {
			for memory in basePoints...maxPoints {
				for perception in basePoints...maxPoints {
					guard intelligence + memory + perception < totalMaxPoints - basePoints * 2 else {break}
					for willpower in basePoints...maxPoints {
						guard intelligence + memory + perception + willpower < totalMaxPoints - basePoints else {break}
						let charisma = totalMaxPoints - (intelligence + memory + perception + willpower)
						guard charisma <= maxPoints else {continue}
						
						let attributes = Character.Attributes(intelligence: intelligence, memory: memory, perception: perception, willpower: willpower, charisma: charisma)
						
						let trainingTime = skillPoints.reduce(0) { (t, i) -> TimeInterval in
							let primary = attributes[i.key.primary]
							let secondary = attributes[i.key.secondary]
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
		self = optimal
	}
}
