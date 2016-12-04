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
	let rank: Int
	let startSkillPoints: Int
	
	private var skillPoints: Int {
		get {
			if let trainingStartDate = trainingStartDate, let trainingEndDate = trainingEndDate, trainingEndDate < Date() {
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
			return startSkillPoints
		}
	}
	
	var trainingProgress: Double {
		get {
			let start = Double(skillPoints(at: self.level))
			let end = Double(skillPoints(at: self.level + 1))
			let sp = Double(skillPoints)
			let progress = (sp - start) / (end - start);
			return progress
		}
	}
	
	let level: Int
	let trainingStartDate: Date?
	let trainingEndDate: Date?
	
	init?(type: NCDBInvType, level: Int = 0, startSkillPoints: Int = 0, trainingStartDate: Date? = nil, trainingEndDate: Date? = nil) {
		var typeID: Int = 0
		var typeName: String?
		var primaryAttributeID: Float?
		var secondaryAttributeID: Float?
		var rank: Float?
		type.managedObjectContext?.performAndWait {
			typeID = Int(type.typeID)
			typeName = type.typeName
			let attributes = type.allAttributes
			primaryAttributeID = attributes[NCDBAttributeID.PrimaryAttribute.rawValue]?.value
			secondaryAttributeID = attributes[NCDBAttributeID.SecondaryAttribute.rawValue]?.value
			rank = attributes[NCDBAttributeID.SkillTimeConstant.rawValue]?.value
		}
		if let typeName = typeName, let primaryAttributeID = primaryAttributeID, let secondaryAttributeID = secondaryAttributeID, let rank = rank {
			self.typeID = typeID
			self.typeName = typeName
			self.primaryAttributeID = NCDBAttributeID(rawValue: Int(primaryAttributeID)) ?? .None
			self.secondaryAttributeID = NCDBAttributeID(rawValue: Int(secondaryAttributeID)) ?? .None
			self.rank = Int(rank)
			self.level = level
			self.startSkillPoints = startSkillPoints
			self.trainingStartDate = trainingStartDate
			self.trainingEndDate = trainingEndDate
		}
		else {
			return nil
		}
	}
	
	convenience init?(type: NCDBInvType, skill: EVESkillQueueItem) {
		self.init(type: type, level: skill.level - 1, startSkillPoints: skill.startSP, trainingStartDate: skill.queuePosition == 0 ? skill.startTime : nil, trainingEndDate: skill.queuePosition == 0 ? skill.endTime : nil)
	}
	
	class func rank(skillPoints: Int, level: Int) -> Int {
		return Int(round(Double(skillPoints) / (pow(2.0, 2.5 * Double(level) - 2.5) * 250.0)));
	}
	
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
		return trainingTime(to: self.level + 1, characterAttributes: characterAttributes)
	}

	//MARK: Hashable
	
	var hashValue: Int {
		get {
			var dic = [String: AnyHashable]()
			dic["typeID"] = typeID
			dic["level"] = level
			dic["startSkillPoints"] = startSkillPoints
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
