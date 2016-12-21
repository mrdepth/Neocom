//
//  NCCharacter.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class NCCharacter {
	let skills: [Int: NCSkill]
	let attributes: NCCharacterAttributes
	
	init(attributes: NCCharacterAttributes? = nil, skills: ESSkills? = nil, skillQueue: [ESSkillQueueItem]? = nil) {
		var skillsMap = [Int: NCSkill]()
		var map = [IndexPath: ESSkillQueueItem]()
		if let skillQueue = skillQueue {
			for item in skillQueue {
				map[IndexPath(indexes: [item.skillID, item.finishedLevel - 1])] = item
			}
		}
		
		if let skills = skills {
			NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
				let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
				for skill in skills.skills {
					guard let type = invTypes[skill.skillID] else {continue}
					if let item = map[IndexPath(indexes: [skill.skillID, skill.currentSkillLevel])],
						let skill = NCSkill(type: type, skill: item){
						skillsMap[skill.typeID] = skill
					}
					else if let skill = NCSkill(type: type, level: skill.currentSkillLevel, startSkillPoints: skill.skillPointsInSkill) {
						skillsMap[skill.typeID] = skill
					}
				}
			})
		}
		self.attributes = attributes ?? NCCharacterAttributes()
		self.skills = skillsMap
	}
	
	class func load(account: NCAccount?, completionHandler: @escaping(NCCharacter) -> Void) {
		if let account = account {
			let dataManager = NCDataManager(account: account)
			var skills: ESSkills?
			var skillQueue: [ESSkillQueueItem]?
			
			let dispatchGroup = DispatchGroup()
			
			dispatchGroup.enter()
			dataManager.skills { result in
				switch result {
				case let .success(value: value, cacheRecordID: nil):
					skills = value
				default:
					break
				}
				dispatchGroup.leave()
			}
			
			dispatchGroup.enter()
			dataManager.skillQueue { result in
				switch result {
				case let .success(value: value, cacheRecordID: nil):
					skillQueue = value
				default:
					break
				}
				dispatchGroup.leave()
			}
			
			dispatchGroup.notify(queue: .global(qos: .background)) {
				autoreleasepool {
					let character = NCCharacter(attributes: nil, skills: skills, skillQueue: skillQueue)
					DispatchQueue.main.async {
						completionHandler(character)
					}
				}
			}
		}
		else {
			completionHandler(NCCharacter())
		}
	}
}
