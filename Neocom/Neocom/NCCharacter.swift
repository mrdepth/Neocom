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
	
	class func load(account: NCAccount?, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: @escaping(NCResult<NCCharacter>) -> Void) {
		if let account = account {
			let dataManager = NCDataManager(account: account)
			var skillsResult: NCCachedResult<ESI.Skills.CharacterSkills>?
			var skillQueueResult: NCCachedResult<[ESI.Skills.SkillQueueItem]>?
			var attributesResult: NCCachedResult<ESI.Skills.CharacterAttributes>?
			var implantsResult: NCCachedResult<[Int]>?
			
			let dispatchGroup = DispatchGroup()
			
			let progress = Progress(totalUnitCount: 4)
			
			progress.perform {
				dispatchGroup.enter()
				dataManager.skills { result in
					skillsResult = result
					dispatchGroup.leave()
				}
			}
			
			progress.perform {
				dispatchGroup.enter()
				dataManager.skillQueue { result in
					skillQueueResult = result
					dispatchGroup.leave()
				}
			}
			
			progress.perform {
				dispatchGroup.enter()
				dataManager.attributes { result in
					attributesResult = result
					dispatchGroup.leave()
				}
			}

			progress.perform {
				dispatchGroup.enter()
				dataManager.implants { result in
					implantsResult = result
					dispatchGroup.leave()
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				guard let skills = skillsResult?.value,
					let skillQueue = skillQueueResult?.value,
					let attributes = attributesResult?.value,
					let implants = implantsResult?.value else {
						completionHandler(.failure(skillsResult?.error ?? skillQueueResult?.error ?? attributesResult?.error ?? implantsResult?.error ?? NCDataManagerError.internalError))
						return
				}
				
				let records = [skillsResult?.cacheRecord, skillQueueResult?.cacheRecord, attributesResult?.cacheRecord, implantsResult?.cacheRecord].compactMap{$0}

				DispatchQueue.global(qos: .background).async {
					autoreleasepool {
						let character = NCCharacter(attributes: NCCharacterAttributes(attributes: attributes, implants: implants), skills: skills, skillQueue: skillQueue)
						
						DispatchQueue.main.async {
							character.observer = NCManagedObjectObserver(managedObjects: records) { [weak character] (updated, deleted) in
								guard let character = character else {return}
								guard updated != nil else {return}
								
								guard let skills = skillsResult?.value,
									let skillQueue = skillQueueResult?.value,
									let attributes = attributesResult?.value,
									let implants = implantsResult?.value else {
										return
								}
								
								DispatchQueue.global(qos: .background).async {
									autoreleasepool {
										character.load(attributes: NCCharacterAttributes(attributes: attributes, implants: implants), skills: skills, skillQueue: skillQueue)
										
										DispatchQueue.main.async {
											NotificationCenter.default.post(name: .NCCharacterChanged, object: character)
										}
									}
								}
							}
							completionHandler(.success(character))
						}
					}
				}

			}
		}
		else {
			completionHandler(.success(NCCharacter()))
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
