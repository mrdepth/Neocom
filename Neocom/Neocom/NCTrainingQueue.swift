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
	
	var level: Int {
		return skill.level! + 1
	}
	
	init?(type: NCDBInvType, skill: NCSkill?, level: Int) {
		guard level > 0 && level <= 5 else {return nil}
		
		if skill?.level == level - 1 {
			guard let skill = NCSkill(type: type, level: level - 1, startSkillPoints: skill?.startSkillPoints, trainingStartDate: skill?.trainingStartDate, trainingEndDate: skill?.trainingEndDate) else {return nil}
			self.skill = skill
		}
		else {
			guard let skill = NCSkill(type: type, level: level - 1) else {return nil}
			self.skill = skill
		}
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
	
	func addRequiredSkills(type: NCDBInvType) {
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
		
		addRequiredSkills(type: type)
		for level in (trainedLevel + 1)...level {
			if skills.first(where: {return $0.skill.typeID == typeID && $0.level == level}) == nil {
				guard let trainingSkill = NCTrainingSkill(type: type, skill: trainedSkill, level: level) else {break}
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
}
