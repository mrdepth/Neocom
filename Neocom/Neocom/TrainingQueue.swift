//
//  TrainingQueue.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class TrainingQueue {
	struct Item: Hashable {
		let skill: NCCharacter.Skill
		let targetLevel: Int
		let startSP: Int
		let finishSP: Int
	}
	let character: NCCharacter
	var queue: [Item] = []
	
	var trainedSkillLevels: [Int: Int] = [:]
	
	init(character: NCCharacter) {
		self.character = character
		trainedSkillLevels = Dictionary(character.trainedSkills.map{($0.skill.typeID, $0.characterSkill.trainedSkillLevel)}) { max($0, $1) }
	}
	
	func add(_ skillType: SDEInvType, level: Int) {
		guard let skill = NCCharacter.Skill(type: skillType) else {return}
		addRequiredSkills(for: skillType)
		
		let typeID = Int(skillType.typeID)
		let trainedLevel = trainedSkillLevels[typeID] ?? 0
		
		guard trainedLevel < level else {return}
		
		let queuedLevels = IndexSet(queue.filter({$0.skill.typeID == typeID}).map{$0.targetLevel})
		
		for i in (trainedLevel + 1)...level {
			if !queuedLevels.contains(i) {
				let sp = character.skillQueue.first(where: {$0.skill.typeID == skill.typeID && $0.queuedSkill.finishedLevel == i})?.queuedSkill.trainingStartSP
				queue.append(Item(skill: skill, targetLevel: i, startSP: sp))
			}
		}
	}

	func add(_ mastery: SDECertMastery) {
		mastery.skills?.forEach {
			guard let skill = $0 as? SDECertSkill else {return}
			guard let type = skill.type else {return}
			add(type, level: max(Int(skill.skillLevel), 1))
		}
	}

	func addRequiredSkills(for type: SDEInvType) {
		type.requiredSkills?.forEach {
			guard let requiredSkill = ($0 as? SDEInvTypeRequiredSkill) else {return}
			guard let type = requiredSkill.type else {return}
			add(type, level: Int(requiredSkill.skillLevel))
		}
	}

	func addRequiredSkills(for activity: SDEIndActivity) {
		activity.requiredSkills?.forEach {
			guard let requiredSkill = ($0 as? SDEIndRequiredSkill) else {return}
			guard let type = requiredSkill.skillType else {return}
			add(type, level: Int(requiredSkill.skillLevel))
		}
	}
	
	func remove(_ item: TrainingQueue.Item) {
		let indexes = IndexSet(queue.enumerated().filter {$0.element.skill.typeID == item.skill.typeID && $0.element.targetLevel >= item.targetLevel}.map{$0.offset})
		indexes.reversed().forEach {queue.remove(at: $0)}
		indexes.rangeView.reversed().forEach { queue.removeSubrange($0) }
	}

	func trainingTime() -> TimeInterval {
		return trainingTime(with: character.attributes + character.augmentations)
	}

	func trainingTime(with attributes: NCCharacter.Attributes) -> TimeInterval {
		return queue.map {$0.trainingTime(with: attributes)}.reduce(0, +)
	}

}

extension TrainingQueue.Item {
	
	init(skill: NCCharacter.Skill, targetLevel: Int, startSP: Int?) {
		self.skill = skill
		self.targetLevel = targetLevel
		self.startSP = startSP ?? skill.skillPoints(at: targetLevel - 1)
		finishSP = skill.skillPoints(at: targetLevel)
	}
	
	func trainingTime(with attributes: NCCharacter.Attributes) -> TimeInterval {
		return Double(finishSP - startSP) / skill.skillpointsPerSecond(with: attributes)
	}
}
