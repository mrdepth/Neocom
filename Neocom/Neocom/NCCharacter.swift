//
//  NCCharacter.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import CoreData

class NCCharacter {
	
	private(set) var skills: [Int: NCSkill]
	private(set) var skillQueue: [ESI.Skills.SkillQueueItem]
	private(set) var attributes: NCCharacterAttributes
	
	init(attributes: NCCharacterAttributes? = nil, skills: ESI.Skills.CharacterSkills? = nil, skillQueue: [ESI.Skills.SkillQueueItem]? = nil) {
		self.skills = [:]
		self.skillQueue = []
		self.attributes = attributes ?? NCCharacterAttributes()
		load(attributes: attributes, skills: skills, skillQueue: skillQueue)
	}
	
	init(attributes: NCCharacterAttributes, skills: [Int: NCSkill], skillQueue: [ESI.Skills.SkillQueueItem]) {
		self.attributes = attributes
		self.skills = skills
		self.skillQueue = skillQueue
	}
	
	var observer: NCManagedObjectObserver?
	
	class func load(account: NCAccount?, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> Future<NCCharacter> {
		if let account = account {
			let progress = Progress(totalUnitCount: 4)

			return NCStorage.sharedStorage!.performBackgroundTask { context -> NCCharacter in
				let account = try context.existingObject(with: account.objectID) as! NCAccount
				let dataManager = NCDataManager(account: account)
				let skills = try progress.perform {dataManager.skills()}.get()
				let skillQueue = try progress.perform {dataManager.skillQueue()}.get()
				let attributes = try progress.perform {dataManager.attributes()}.get()
				let implants = try progress.perform {dataManager.implants()}.get()
				guard let skillsValue = skills.value,
					let skillQueueValue = skillQueue.value,
					let attributesValue = attributes.value,
					let implantsValue = implants.value else {
						throw NCDataManagerError.noCacheData
				}
				
				let character = NCCharacter(attributes: NCCharacterAttributes(attributes: attributesValue, implants: implantsValue), skills: skillsValue, skillQueue: skillQueueValue)
				DispatchQueue.main.async {
					character.observer = NCManagedObjectObserver(managedObjects: [skills.cacheRecord(in: NCCache.sharedCache!.viewContext), skillQueue.cacheRecord(in: NCCache.sharedCache!.viewContext), attributes.cacheRecord(in: NCCache.sharedCache!.viewContext), implants.cacheRecord(in: NCCache.sharedCache!.viewContext)]) { [weak character] (updated, deleted) in
						guard let character = character else {return}
						guard updated != nil else {return}
						guard let skillsValue = skills.value,
							let skillQueueValue = skillQueue.value,
							let attributesValue = attributes.value,
							let implantsValue = implants.value else {
								return
						}
						
						DispatchQueue.global(qos: .utility).async {
							character.load(attributes: NCCharacterAttributes(attributes: attributesValue, implants: implantsValue), skills: skillsValue, skillQueue: skillQueueValue)
							}.then(on: .main) {
								NotificationCenter.default.post(name: .NCCharacterChanged, object: character)
						}
					}
				}
				return character
			}
		}
		else {
			return .init(NCCharacter())
		}
	}
	
	private func load(attributes: NCCharacterAttributes? = nil, skills: ESI.Skills.CharacterSkills? = nil, skillQueue: [ESI.Skills.SkillQueueItem]? = nil) {
		var skillsMap = [Int: NCSkill]()
		let skillQueue = skillQueue?.filter {$0.finishDate != nil}
		if let skills = skills {
			NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
				let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
				
				var skillLevels: [Int : Int] = [:]
				var map: [IndexPath: ESI.Skills.SkillQueueItem] = [:]
				
				skills.skills.forEach {
					skillLevels[$0.skillID] = $0.trainedSkillLevel
				}
				
				let date = Date()
				
				skillQueue?.filter {$0.finishDate! <= date}.forEach {
					skillLevels[$0.skillID] = $0.finishedLevel
				}
				
				skillQueue?.filter {$0.finishDate! > date}.forEach {
					map[IndexPath(indexes: [$0.skillID, $0.finishedLevel - 1])] = $0
				}
				
				skillLevels.forEach { (typeID, level) in
					guard let type = invTypes[typeID] else {return}
					
					if let item = map[IndexPath(indexes: [typeID, level])], let skill = NCSkill(type: type, skill: item) {
						skillsMap[typeID] = skill
					}
					else if let skill = NCSkill(type: type, level: level) {
						skillsMap[typeID] = skill
					}
				}
				
			})
		}
		self.attributes = attributes ?? NCCharacterAttributes()
		self.skills = skillsMap
		self.skillQueue = skillQueue ?? []
	}
}
