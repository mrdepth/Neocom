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
		var skillsMap = [Int: NCSkill]()
		var map: [IndexPath: ESI.Skills.SkillQueueItem] = [:]
		if let skillQueue = skillQueue {
			for item in skillQueue {
				map[IndexPath(indexes: [item.skillID, item.finishedLevel - 1])] = item
			}
		}
		if let skills = skills {
			NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
				let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
				for skill in skills.skills ?? [] {
					guard let skillID = skill.skillID else {continue}
					guard let currentSkillLevel = skill.currentSkillLevel else {continue}
					guard let type = invTypes[skillID] else {continue}

					if let item = map[IndexPath(indexes: [skillID, currentSkillLevel])],
						let skill = NCSkill(type: type, skill: item){
						skillsMap[skill.typeID] = skill
					}
					else if let skill = NCSkill(type: type, level: currentSkillLevel, startSkillPoints: Int(skill.skillpointsInSkill ?? 0)) {
						skillsMap[skill.typeID] = skill
					}
				}
			})
		}
		self.attributes = attributes ?? NCCharacterAttributes()
		self.skills = skillsMap
		self.skillQueue = skillQueue ?? []
	}
	
	var observer: NCManagedObjectObserver?
	
	class func load(account: NCAccount?, completionHandler: @escaping(NCResult<NCCharacter>) -> Void) {
		if let account = account {
			let dataManager = NCDataManager(account: account)
			var skillsResult: NCCachedResult<ESI.Skills.CharacterSkills>?
			var skillQueueResult: NCCachedResult<[ESI.Skills.SkillQueueItem]>?
			var clonesResult: NCCachedResult<EVE.Char.Clones>?
			
			let dispatchGroup = DispatchGroup()
			
			let progress = Progress(totalUnitCount: 3)
			
			progress.becomeCurrent(withPendingUnitCount: 1)
			dispatchGroup.enter()
			dataManager.skills { result in
				skillsResult = result
				dispatchGroup.leave()
			}
			progress.resignCurrent()
			
			progress.becomeCurrent(withPendingUnitCount: 1)
			dispatchGroup.enter()
			dataManager.skillQueue { result in
				skillQueueResult = result
				dispatchGroup.leave()
			}
			progress.resignCurrent()
			
			progress.becomeCurrent(withPendingUnitCount: 1)
			dispatchGroup.enter()
			dataManager.clones { result in
				clonesResult = result
				dispatchGroup.leave()
			}
			progress.resignCurrent()

			
			dispatchGroup.notify(queue: .global(qos: .background)) {
				autoreleasepool {
					var result: NCResult<NCCharacter>?
					defer {
						DispatchQueue.main.async {
							completionHandler(result!)
						}
					}
					
					var skills: ESI.Skills.CharacterSkills?
					var skillsRecord: NCCacheRecord?
					var skillQueue: [ESI.Skills.SkillQueueItem]?
					var skillQueueRecord: NCCacheRecord?
					var clones: EVE.Char.Clones?
					var clonesRecord: NCCacheRecord?
					
					switch skillsResult {
					case let .success(value, cacheRecord)?:
						skills = value
						skillsRecord = cacheRecord
						break
					case let .failure(error)?:
						result = .failure(error)
						return
					default:
						result = .failure(ESIError.internalError)
						return
					}
					
					switch skillQueueResult {
					case let .success(value, cacheRecord)?:
						skillQueue = value
						skillQueueRecord = cacheRecord
						break
					case let .failure(error)?:
						result = .failure(error)
						return
					default:
						result = .failure(ESIError.internalError)
						return
					}
					
					switch clonesResult {
					case let .success(value, cacheRecord)?:
						clones = value
						clonesRecord = cacheRecord
						break
					case let .failure(error)?:
						result = .failure(error)
						return
					default:
						result = .failure(ESIError.internalError)
						return
					}
					
					
					let character = NCCharacter(attributes: NCCharacterAttributes(clones: clones!), skills: skills!, skillQueue: skillQueue!)
					result = .success(character)
					
					character.observer = NCManagedObjectObserver() {[weak character] (updated, deleted) in
						guard let character = character else {return}
						guard let updated = updated else {return}
						
						NCCache.sharedCache?.performBackgroundTask { managedObjectContext in
							var skills: ESI.Skills.CharacterSkills?
							var skillQueue: [ESI.Skills.SkillQueueItem]?
							var skillsMap = [Int: NCSkill]()
							var attributes: NCCharacterAttributes?
							
							synchronized(self) {
								for object in updated {
									if object.objectID == skillsRecord?.objectID {
										skills = ((try? managedObjectContext.existingObject(with: object.objectID)) as? NCCacheRecord)?.data?.data as? ESI.Skills.CharacterSkills
									}
									else if object.objectID == skillQueueRecord?.objectID {
										skillQueue = ((try? managedObjectContext.existingObject(with: object.objectID)) as? NCCacheRecord)?.data?.data as? [ESI.Skills.SkillQueueItem]
									}
									else if object.objectID == clonesRecord?.objectID {
										guard let clones = ((try? managedObjectContext.existingObject(with: object.objectID)) as? NCCacheRecord)?.data?.data as? EVE.Char.Clones else {continue}
										attributes = NCCharacterAttributes(clones: clones)
									}
								}
								
								var map: [IndexPath: ESI.Skills.SkillQueueItem] = [:]
								for item in skillQueue ?? character.skillQueue {
									map[IndexPath(indexes: [item.skillID, item.finishedLevel - 1])] = item
								}
								
								if let skills = skills {
									NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
										let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
										for skill in skills.skills ?? [] {
											guard let skillID = skill.skillID else {continue}
											guard let currentSkillLevel = skill.currentSkillLevel else {continue}
											guard let type = invTypes[skillID] else {continue}
											if let item = map[IndexPath(indexes: [skillID, currentSkillLevel])],
												let skill = NCSkill(type: type, skill: item) {
												skillsMap[skill.typeID] = skill
											}
											else if let skill = NCSkill(type: type, level: currentSkillLevel, startSkillPoints: Int(skill.skillpointsInSkill ?? 0)) {
												skillsMap[skill.typeID] = skill
											}
										}
									})
								}
								else if skillQueue != nil {
									skillsMap = character.skills
									NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
										let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
										for (_, skill) in skillsMap {
											if let item = map[IndexPath(indexes: [skill.typeID, skill.level ?? 0])],
												let type = invTypes[skill.typeID],
												let skill = NCSkill(type: type, skill: item) {
												skillsMap[skill.typeID] = skill
											}
										}
									})
								}
								else {
									skillsMap = character.skills
								}
							}
							DispatchQueue.main.async {
								character.skillQueue = skillQueue ?? character.skillQueue
								character.skills = skillsMap
								character.attributes = attributes ?? character.attributes
								NotificationCenter.default.post(name: .NCCharacterChanged, object: character)
							}
						}
						
					}
					
					
				}
			}
		}
		else {
			completionHandler(.success(NCCharacter()))
		}

	}
}
