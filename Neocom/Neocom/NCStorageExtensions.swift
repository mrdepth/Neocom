//
//  NCStorageExtensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import CoreData

extension NCAccount {
	
	@nonobjc static var current: NCAccount? = {
		guard let url = UserDefaults.standard.url(forKey: UserDefaults.Key.NCCurrentAccount) else {return nil}
		guard let objectID = NCStorage.sharedStorage?.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) else {return nil}
		return (try? NCStorage.sharedStorage?.viewContext.existingObject(with: objectID)) as? NCAccount
		}() {
		didSet {
			NotificationCenter.default.post(name: .NCCurrentAccountChanged, object: current)
			if let objectID = current?.objectID {
				UserDefaults.standard.set(objectID.uriRepresentation(), forKey: UserDefaults.Key.NCCurrentAccount)
			}
			else {
				UserDefaults.standard.removeObject(forKey: UserDefaults.Key.NCCurrentAccount)
			}
		}
	}

	var token: OAuth2Token {
		get {
			let scopes = (self.scopes as? Set<NCScope>)?.flatMap {
				return $0.name
			} ?? []
			
			let token = OAuth2Token(accessToken: accessToken ?? "", refreshToken: refreshToken ?? "", tokenType: tokenType ?? "", scopes: scopes, characterID: characterID, characterName: characterName ?? "", realm: realm ?? "")
			token.expiresOn = expiresOn as Date? ?? Date.distantPast
			return token
		}
		set {
			let token = newValue
			if accessToken != token.accessToken {accessToken = token.accessToken}
			if refreshToken != token.refreshToken {refreshToken = token.refreshToken}
			if tokenType != token.tokenType {tokenType = token.tokenType}
			if characterID != token.characterID {characterID = token.characterID}
			if characterName != token.characterName {characterName = token.characterName}
			if realm != token.realm {realm = token.realm}
			if let expiresOn = token.expiresOn as NSDate?, expiresOn != self.expiresOn {
				self.expiresOn = expiresOn
			}
			let newScopes = Set<String>(token.scopes)
			
			let toInsert: Set<String>
			if let scopes = self.scopes as? Set<NCScope> {
				let toDelete = scopes.filter {
					return !newScopes.contains($0.name!)
				}
				for scope in toDelete {
					managedObjectContext!.delete(scope)
				}
				toInsert = newScopes.symmetricDifference(scopes.map {return $0.name!})
			}
			else {
				toInsert = newScopes
			}
			
			for name in toInsert {
				let scope = NCScope(entity: NSEntityDescription.entity(forEntityName: "Scope", in: managedObjectContext!)!, insertInto: managedObjectContext!)
				scope.name = name
				scope.account = self
			}
		}
	}
	
	var activeSkillPlan: NCSkillPlan? {
		if let skillPlan = skillPlans?.filtered(using: NSPredicate(format: "active == TRUE")).first as? NCSkillPlan {
			return skillPlan
		}
		else if let skillPlan = skillPlans?.anyObject() as? NCSkillPlan {
			skillPlan.active = true
			if skillPlan.managedObjectContext?.hasChanges ?? false {
				try? skillPlan.managedObjectContext?.save()
			}
			return skillPlan
		}
		else if let managedObjectContext = managedObjectContext {
			let skillPlan = NCSkillPlan(entity: NSEntityDescription.entity(forEntityName: "SkillPlan", in: managedObjectContext)!, insertInto: managedObjectContext)
			skillPlan.active = true
			skillPlan.account = self
			skillPlan.name = NSLocalizedString("Default", comment: "")
			if skillPlan.managedObjectContext?.hasChanges ?? false {
				try? skillPlan.managedObjectContext?.save()
			}
			return skillPlan
		}
		else {
			return nil
		}
	}
	
	class func accounts(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCAccount> {
		return NCFetchedCollection<NCAccount>(entityName: "Account", predicateFormat: "uuid == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}

extension NCSetting {
	class func setting(key: String) -> NCSetting? {
		guard let context = NCStorage.sharedStorage?.viewContext else {return nil}
		
		let request = NSFetchRequest<NCSetting>(entityName: "Setting")
		request.predicate = NSPredicate(format: "key == %@", key)
		request.fetchLimit = 1
		
		if let setting = (try? context.fetch(request))?.first {
			return setting
		}
		else {
			let setting = NCSetting(entity: NSEntityDescription.entity(forEntityName: "Setting", in: context)!, insertInto: context)
			setting.key = key
			//setting.value = defaultValue as? NSObject
			return setting
		}
	}
}

extension NCSkillPlan {
	func add(trainingQueue: NCTrainingQueue) {
		var set = Set<IndexPath>()
		var lastPosition = 0 as Int32
		for skill in self.skills?.allObjects as? [NCSkillPlanSkill] ?? [] {
			set.insert(IndexPath(indexes: [Int(skill.typeID), Int(skill.level)]))
			lastPosition = max(lastPosition, skill.position)
		}
		for skill in trainingQueue.skills {
			if !set.contains(IndexPath(indexes: [skill.skill.typeID, skill.level])) {
				let skillPlanSkill = NCSkillPlanSkill(entity: NSEntityDescription.entity(forEntityName: "SkillPlanSkill", in: managedObjectContext!)!, insertInto: managedObjectContext!)
				skillPlanSkill.skillPlan = self
				skillPlanSkill.typeID = Int32(skill.skill.typeID)
				skillPlanSkill.level = Int16(skill.level)
				lastPosition += 1
				skillPlanSkill.position = lastPosition
			}
		}
	}
	
	func remove(skill: NCSkillPlanSkill) {
		skill.managedObjectContext?.delete(skill)
	}
}

extension NCFitCharacter {
	class func fitCharacters(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCFitCharacter> {
		return NCFetchedCollection<NCFitCharacter>(entityName: "FitCharacter", predicateFormat: "uuid == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}
