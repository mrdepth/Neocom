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
	
	struct Attributes: Hashable, Codable {
		var intelligence: Int
		var memory: Int
		var perception: Int
		var willpower: Int
		var charisma: Int
	}
	
	struct SkillQueueItem: Hashable, Codable {
		var skill: Skill
		var queuedSkill: ESI.Skills.SkillQueueItem
	}
	
	var attributes: Attributes
	var augmentations: Attributes
	var trainedSkills: [Int: ESI.Skills.CharacterSkills.Skill]
	var skillQueue: [SkillQueueItem]
	
	
	static let empty = Character(attributes: .default, augmentations: .none, trainedSkills: [:], skillQueue: [])
	
}

extension Character {
	init(attributes: ESI.Skills.CharacterAttributes, skills: ESI.Skills.CharacterSkills, skillQueue: [ESI.Skills.SkillQueueItem], implants: [Int], context: SDEContext) {
		let characterAttributes = Character.Attributes(intelligence: attributes.intelligence,
													   memory: attributes.memory,
													   perception: attributes.perception,
													   willpower: attributes.willpower,
													   charisma: attributes.charisma)
		
		var augmentations = Character.Attributes.none
		
		for implant in implants {
			guard let type = context.invType(implant) else {continue}
			let attributes = [SDEAttributeID.intelligenceBonus, SDEAttributeID.memoryBonus, SDEAttributeID.perceptionBonus, SDEAttributeID.willpowerBonus, SDEAttributeID.charismaBonus].lazy.map({($0, Int(type[$0]?.value ?? 0))})
			guard let value = attributes.first(where: {$0.1 > 0}) else {continue}
			augmentations[value.0] += value.1
		}
		
		var trainedSkills = Dictionary(skills.skills.map { ($0.skillID, $0)}, uniquingKeysWith: {
			$0.trainedSkillLevel > $1.trainedSkillLevel ? $0 : $1
		})
		
		let currentDate = Date()
		var validSkillQueue = skillQueue.filter{$0.finishDate != nil}
		let i = validSkillQueue.partition(by: {$0.finishDate! > currentDate})
		for skill in validSkillQueue[..<i] {
			guard let endSP = skill.levelEndSP ?? context.invType(skill.skillID).flatMap({Character.Skill(type: $0)})?.skillPoints(at: skill.finishedLevel) else {continue}
			
			let skill = ESI.Skills.CharacterSkills.Skill(activeSkillLevel: skill.finishedLevel, skillID: skill.skillID, skillpointsInSkill: Int64(endSP), trainedSkillLevel: skill.finishedLevel)
			trainedSkills[skill.skillID] = trainedSkills[skill.skillID].map {$0.trainedSkillLevel > skill.trainedSkillLevel ? $0 : skill} ?? skill
		}
		
		let sq = validSkillQueue[i...].sorted{$0.queuePosition < $1.queuePosition}.compactMap { i -> Character.SkillQueueItem? in
			guard let type = context.invType(i.skillID), let skill = Character.Skill(type: type) else {return nil}
			let item = Character.SkillQueueItem(skill: skill, queuedSkill: i)
			trainedSkills[i.skillID]?.skillpointsInSkill = Int64(item.skillPoints)
			return item
		}
		
		self.attributes = characterAttributes
		self.augmentations = augmentations
		self.trainedSkills = trainedSkills
		self.skillQueue = sq
	}
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
	
	func level(with skillPoints: Int) -> Int {
		if (skillPoints == 0 || rank == 0) {
			return 0
		}
		let level = (log(Double(skillPoints)/(250.0 * Double(rank))) / log(2.0) + 2.5) / 2.5;
		return Int(level.rounded(.down))
	}
	
	func skillPointsPerSecond(with attributes: Character.Attributes) -> Double {
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
			case .intelligence, .intelligenceBonus:
				return intelligence
			case .memory, .memoryBonus:
				return memory
			case .perception, .perceptionBonus:
				return perception
			case .willpower, .willpowerBonus:
				return willpower
			case .charisma, .charismaBonus:
				return charisma
			default:
				return 0
			}
		}
		set {
			switch key {
			case .intelligence, .intelligenceBonus:
				intelligence = newValue
			case .memory, .memoryBonus:
				memory = newValue
			case .perception, .perceptionBonus:
				perception = newValue
			case .willpower, .willpowerBonus:
				willpower = newValue
			case .charisma, .charismaBonus:
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
		return Double(skillPointsToLevelUp) / skill.skillPointsPerSecond(with: attributes)
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
