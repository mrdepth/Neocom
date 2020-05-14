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
	
	static var current: NCAccount? = {
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
	
	var isInvalid: Bool {
		return refreshToken?.isEmpty != false
	}

	var token: OAuth2Token {
		get {
			let scopes = (self.scopes as? Set<NCScope>)?.compactMap {
				return $0.name
			} ?? []
			
			let token = OAuth2Token(accessToken: accessToken ?? "", refreshToken: refreshToken ?? "", tokenType: tokenType ?? "", expiresOn: expiresOn as Date? ?? Date.distantPast, characterID: characterID, characterName: characterName ?? "", realm: realm ?? "", scopes: scopes)
//			let token = OAuth2Token(accessToken: accessToken ?? "", refreshToken: refreshToken ?? "", tokenType: tokenType ?? "", scopes: scopes, characterID: characterID, characterName: characterName ?? "", realm: realm ?? "")
//			token.expiresOn = expiresOn as Date? ?? Date.distantPast
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
			if expiresOn != token.expiresOn {expiresOn = token.expiresOn}
			let newScopes = Set<String>(token.scopes)
			
			let toInsert: Set<String>
			if var scopes = self.scopes as? Set<NCScope> {
				let toDelete = scopes.filter {
					guard let name = $0.name else {return true}
					return !newScopes.contains(name)
				}
				for scope in toDelete {
					managedObjectContext!.delete(scope)
					scopes.remove(scope)
				}
				
				toInsert = newScopes.symmetricDifference(scopes.compactMap {return $0.name})
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
	
	struct Key {
		var rawValue: String
		public init (_ rawValue: String) {
			self.rawValue = rawValue
		}
		
		static let skillQueueNotifications = Key("NCNotificationManager.skillQueue")
		static let skillQueueNotificationsAccounts = Key("NCNotificationManager.skillQueueAccounts")
//
	}
	
	class func setting(key: Key) -> NCSetting? {
		guard let context = NCStorage.sharedStorage?.viewContext else {return nil}
		
		let request = NSFetchRequest<NCSetting>(entityName: "Setting")
		request.predicate = NSPredicate(format: "key == %@", key.rawValue)
		request.fetchLimit = 1
		
		if let setting = (try? context.fetch(request))?.first {
			return setting
		}
		else {
			let setting = NCSetting(entity: NSEntityDescription.entity(forEntityName: "Setting", in: context)!, insertInto: context)
			setting.key = key.rawValue
			//setting.value = defaultValue as? NSObject
			try? context.save()
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


extension NCShoppingItem {
	var totalQuantity: Int32 {
		return quantity * (parent?.totalQuantity ?? 1)
	}
}
