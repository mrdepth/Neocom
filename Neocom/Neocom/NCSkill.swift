//
//  NCSkill.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class NCSkill: Hashable {
	let typeID: Int
	let typeName: String
	let primaryAttributeID: NCDBAttributeID
	let secondaryAttributeID: NCDBAttributeID
	let rank: Float
	let startSkillPoints: Int?
	
	var skillPoints: Int {
		if let trainingStartDate = trainingStartDate,
			let trainingEndDate = trainingEndDate,
			let startSkillPoints = startSkillPoints,
			let level = level,
			trainingEndDate > Date() {
			let endSP = skillPoints(at: level + 1)
			let t = trainingEndDate.timeIntervalSince(trainingStartDate)
			if t > 0 {
				let spps = Double(endSP - startSkillPoints) / t
				let t = trainingEndDate.timeIntervalSinceNow
				let sp = Int(t > 0 ? Double(endSP) - t * spps : Double(endSP))
				return max(sp, startSkillPoints);
			}
			else {
				return endSP
			}
		}
		//return startSkillPoints ?? 0
		return skillPoints(at: level ?? 0)
	}
	
	var trainingProgress: Float {
		guard let level = self.level else {return 0}
		let start = Double(skillPoints(at: level))
		let end = Double(skillPoints(at: level + 1))
		let sp = Double(skillPoints)
		let progress = (sp - start) / (end - start);
		return Float(progress)
	}
	
	let level: Int?
	let trainingStartDate: Date?
	let trainingEndDate: Date?
	
	init?(type: NCDBInvType, level: Int? = nil, startSkillPoints: Int? = nil, trainingStartDate: Date? = nil, trainingEndDate: Date? = nil) {

		let attributes = type.allAttributes

		guard let typeName = type.typeName,
			let primaryAttributeID = attributes[NCDBAttributeID.primaryAttribute.rawValue]?.value,
			let secondaryAttributeID = attributes[NCDBAttributeID.secondaryAttribute.rawValue]?.value,
			let rank = attributes[NCDBAttributeID.skillTimeConstant.rawValue]?.value
			else {
				return nil
		}
		
		self.typeID = Int(type.typeID)
		self.typeName = typeName
		self.primaryAttributeID = NCDBAttributeID(rawValue: Int(primaryAttributeID)) ?? .none
		self.secondaryAttributeID = NCDBAttributeID(rawValue: Int(secondaryAttributeID)) ?? .none
		self.rank = Float(rank)
		self.level = level
		self.startSkillPoints = startSkillPoints
		self.trainingStartDate = trainingStartDate
		self.trainingEndDate = trainingEndDate
	}
	
	convenience init?(type: NCDBInvType, skill: ESI.Skills.SkillQueueItem) {
		self.init(type: type, level: skill.finishedLevel - 1, startSkillPoints: skill.trainingStartSP, trainingStartDate: skill.startDate, trainingEndDate: skill.finishDate)
	}
	
//	class func rank(skillPoints: Int, level: Int) -> Int {
//		return Int(round(Double(skillPoints) / (pow(2.0, 2.5 * Double(level) - 2.5) * 250.0)));
//	}
	
	func skillPoints(at level: Int) -> Int {
		if (level == 0 || rank == 0) {
			return 0
		}
		let sp = pow(2, 2.5 * Double(level) - 2.5) * 250.0 * Double(rank)
		return Int(ceil(sp))
	}
	
	func level(at skillpoints: Int) -> Int {
		if (skillpoints == 0 || rank == 0) {
			return 0
		}
		let level = (log(Double(skillpoints + 1)/(250.0 * Double(rank))) / log(2.0) + 2.5) / 2.5;
		return Int(trunc(level))
	}
	
	func trainingTime(to level: Int, characterAttributes: NCCharacterAttributes) -> TimeInterval {
		return (Double(skillPoints(at: level) - self.skillPoints)) / characterAttributes.skillpointsPerSecond(forSkill: self)
	}

	func trainingTimeToLevelUp(characterAttributes: NCCharacterAttributes) -> TimeInterval {
		return trainingTime(to: 1 + (self.level ?? 0), characterAttributes: characterAttributes)
	}
	
	var skillPointsToLevelUp: Int {
		return skillPoints(at: 1 + (self.level ?? 0)) - self.skillPoints
	}
	
	var isActive: Bool {
		let date = Date()
		if let trainingStartDate = trainingStartDate,
			let trainingEndDate = trainingEndDate,
			trainingEndDate > date && trainingStartDate < date {
			return true
		}
		else {
			return false
		}
	}

	//MARK: Hashable
	
	var hashValue: Int {
		get {
			var dic = [String: AnyHashable]()
			dic["typeID"] = typeID
			if let level = level {
				dic["level"] = level
			}
			if let startSkillPoints = startSkillPoints {
				dic["startSkillPoints"] = startSkillPoints
			}
			
			if let trainingStartDate = trainingStartDate {
				dic["trainingStartDate"] = trainingStartDate
			}
			if let trainingEndDate = trainingEndDate {
				dic["trainingEndDate"] = trainingEndDate
			}
			return dic.hashValue
		}
	}
	
	static func ==(lhs: NCSkill, rhs: NCSkill) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}

}
