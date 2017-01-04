//
//  NCTrainingQueue.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class NCTrainingSkill: Hashable {
	let skill: NCSkill
	let level: Int
	
	init?(type: NCDBInvType?, skill: NCSkill? = nil, level: Int, trainedLevel: Int? = nil) {
		guard level > 0 && level <= 5 else {return nil}
		guard let type = type else {return nil}
		let trainedLevel = trainedLevel ?? skill?.level ?? 0
		guard level > trainedLevel else {return nil}
		
		if let skill = skill, let skillLevel = skill.level, skillLevel == trainedLevel {
			guard let skill = NCSkill(type: type, level: trainedLevel, startSkillPoints: skill.startSkillPoints, trainingStartDate: skill.trainingStartDate, trainingEndDate: skill.trainingEndDate) else {return nil}
			self.skill = skill
		}
		else {
			guard let skill = NCSkill(type: type, level: trainedLevel) else {return nil}
			self.skill = skill
		}
		self.level = level
	}
	
	func trainingTime(characterAttributes: NCCharacterAttributes) -> TimeInterval{
		return skill.trainingTime(to: level, characterAttributes: characterAttributes)
	}
	
	//MARK: Hashable
	
	var hashValue: Int {
		get {
			return skill.hashValue
		}
	}
	
	static func ==(lhs: NCTrainingSkill, rhs: NCTrainingSkill) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}

class NCTrainingQueue {
	let character: NCCharacter
	let trainedSkills: [Int: NCSkill]
	var skills = [NCTrainingSkill]()
	
	init(character: NCCharacter = NCCharacter()) {
		self.character = character
		self.trainedSkills = character.skills
	}
	
	func addRequiredSkills(for type: NCDBInvType) {
		for skill in type.requiredSkills?.array as? [NCDBInvTypeRequiredSkill] ?? [] {
			guard let skillType = skill.skillType else {continue}
			add(skill: skillType, level: Int(skill.skillLevel))
		}
	}
	
	func add(skill type: NCDBInvType, level: Int) {
		let typeID = Int(type.typeID)
		let trainedSkill = trainedSkills[typeID]
		let trainedLevel = trainedSkill?.level ?? 0
		if trainedLevel >= level {
			return
		}
		
		addRequiredSkills(for: type)
		for level in (trainedLevel + 1)...level {
			if skills.first(where: {return $0.skill.typeID == typeID && $0.level == level}) == nil {
				guard let trainingSkill = NCTrainingSkill(type: type,
				                                          skill: trainedSkill,
				                                          level: level,
				                                          trainedLevel: level - 1) else {break}
				skills.append(trainingSkill)
			}
		}
	}
	
	func add(mastery: NCDBCertMastery) {
		for skill in mastery.skills?.allObjects as? [NCDBCertSkill] ?? [] {
			guard let type = skill.type else {continue}
			add(skill: type, level: Int(skill.skillLevel))
		}
	}
	
	func addRequiredSkills(for activity: NCDBIndActivity) {
		for skill in activity.requiredSkills?.allObjects as? [NCDBIndRequiredSkill] ?? [] {
			guard let skillType = skill.skillType else {continue}
			add(skill: skillType, level: Int(skill.skillLevel))
		}
	}
	
	func remove(skill: NCTrainingSkill) {
		var indexes = IndexSet()
		var i = 0
		for item in skills {
			if item.skill.typeID == skill.skill.typeID && item.level >= skill.level {
				indexes.insert(i)
			}
			i += 1
		}
		skills.remove(at: indexes)
	}
	
	func trainingTime(characterAttributes: NCCharacterAttributes) -> TimeInterval{
		var trainingTime: TimeInterval = 0
		for skill in skills {
			trainingTime += skill.trainingTime(characterAttributes: characterAttributes)
		}
		return trainingTime
	}

}
