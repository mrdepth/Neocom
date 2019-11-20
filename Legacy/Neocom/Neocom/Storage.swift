//
//  Storage.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CloudData
import CoreData
import Futures
import EVEAPI
import Expressible

class Storage: PersistentContainer<StorageContext> {
	
	private var oAuth2TokenDidRefreshObserver: NotificationObserver?
	
	class func `default`() -> Storage {
		let container = NSPersistentContainer(name: "Storage", managedObjectModel: NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Storage", withExtension: "momd")!)!)
		
		let directory = URL.init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0])
		try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
		let url = directory.appendingPathComponent("store.sqlite")
		
		let description = NSPersistentStoreDescription()
		description.url = url
		//description.type = CloudStoreType
		description.setOption("Neocom" as NSString, forKey: CloudStoreOptions.recordZoneKey)
		description.setOption(CompressionMethod.zlibDefault as NSNumber, forKey: CloudStoreOptions.binaryDataCompressionMethod)
		description.setOption(NSMergePolicy.overwrite, forKey: CloudStoreOptions.mergePolicy)
		
		container.persistentStoreDescriptions = [description]
		var isLoaded = false
		container.loadPersistentStores { (_, error) in
			isLoaded = error == nil
		}
		
		if !isLoaded {
			try? FileManager.default.removeItem(at: url)
			container.loadPersistentStores { (_, _) in
			}
		}
		
		return Storage(persistentContainer: container)
	}
	
	#if DEBUG
	class func testing() -> Storage {
		let container = NSPersistentContainer(name: "Store", managedObjectModel: NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Storage", withExtension: "momd")!)!)
		let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("store.sqlite")
		try? FileManager.default.removeItem(at: url)
		
		let description = NSPersistentStoreDescription()
		description.url = url
		container.persistentStoreDescriptions = [description]
		container.loadPersistentStores { (description, error) in
			if let error = error {
				fatalError(error.localizedDescription)
			}
		}
		
		return Storage(persistentContainer: container)
	}
	#endif
	
	private static let backwardCompatibility: Void = {
		NSKeyedUnarchiver.setClass(LoadoutDescription.self, forClassName: "Neocom.NCFittingLoadout")
		NSKeyedUnarchiver.setClass(LoadoutDescription.Item.self, forClassName: "Neocom.NCFittingLoadoutItem")
		NSKeyedUnarchiver.setClass(LoadoutDescription.Item.Module.self, forClassName: "Neocom.NCFittingLoadoutModule")
		NSKeyedUnarchiver.setClass(LoadoutDescription.Item.Drone.self, forClassName: "Neocom.NCFittingLoadoutDrone")
		NSKeyedUnarchiver.setClass(FleetDescription.self, forClassName: "Neocom.NCFleetConfiguration")
		NSKeyedUnarchiver.setClass(ImplantSetDescription.self, forClassName: "Neocom.NCImplantSetData")

		NSKeyedArchiver.setClassName("Neocom.NCFittingLoadout", for: LoadoutDescription.self)
		NSKeyedArchiver.setClassName("Neocom.NCFittingLoadoutItem", for: LoadoutDescription.Item.self)
		NSKeyedArchiver.setClassName("Neocom.NCFittingLoadoutModule", for: LoadoutDescription.Item.Module.self)
		NSKeyedArchiver.setClassName("Neocom.NCFittingLoadoutDrone", for: LoadoutDescription.Item.Drone.self)
		NSKeyedArchiver.setClassName("Neocom.NCFleetConfiguration", for: FleetDescription.self)
		NSKeyedArchiver.setClassName("Neocom.NCImplantSetData", for: ImplantSetDescription.self)
	}()
	
	override init(persistentContainer: NSPersistentContainer) {
		_ = Storage.backwardCompatibility
		super.init(persistentContainer: persistentContainer)
		
		oAuth2TokenDidRefreshObserver = NotificationCenter.default.addNotificationObserver(forName: .OAuth2TokenDidRefresh, object: nil, queue: .main) { [weak self] (note) in
			guard let token = note.object as? OAuth2Token else {return}
			guard let account = self?.viewContext.account(with: token) else {return}
			account.oAuth2Token = token
			try? self?.viewContext.save()
		}
	}
}

struct StorageContext: PersistentContext {
	var managedObjectContext: NSManagedObjectContext
	
	var accounts: [Account] {
		return (try? managedObjectContext.from(Account.self).fetch()) ?? []
	}
	
	func account(with token: OAuth2Token) -> Account? {
		return (try? managedObjectContext.from(Account.self).filter(\Account.characterID == token.characterID).first()) ?? nil
	}
	
	func newAccount(with token: OAuth2Token) -> Account {
		let account = Account(context: managedObjectContext)
		account.oAuth2Token = token
		account.uuid = UUID().uuidString
		return account
	}
	
	func newFolder(named name: String) -> AccountsFolder {
		let folder = AccountsFolder(context: managedObjectContext)
		folder.name = name
		return folder
	}
	
	var currentAccount: Account? {
		guard let url = Services.settings.currentAccount else {return nil}
		guard let objectID = Services.storage.managedObjectID(forURIRepresentation: url) else {return nil}
		return (try? existingObject(with: objectID)) ?? nil
	}

	func setCurrentAccount(_ account: Account?) -> Void {
		Services.settings.currentAccount = account?.objectID.uriRepresentation()
		NotificationCenter.default.post(name: .didChangeAccount, object: account)
	}
	
	func marketQuickItems() -> [MarketQuickItem]? {
		return (try? managedObjectContext.from(MarketQuickItem.self).fetch()) ?? nil
	}
	
	func marketQuickItem(with typeID: Int) -> MarketQuickItem? {
		return (try? managedObjectContext
			.from(MarketQuickItem.self)
			.filter(\MarketQuickItem.typeID == typeID).first()) ?? nil
	}

}

extension Account {
	var oAuth2Token: OAuth2Token? {
		get {
			let scopes = (self.scopes as? Set<Scope>)?.compactMap {
				return $0.name
				} ?? []
			guard let accessToken = accessToken,
				let refreshToken = refreshToken,
				let tokenType = tokenType,
				let characterName = characterName,
				let realm = realm else {return nil}
			
			let token = OAuth2Token(accessToken: accessToken, refreshToken: refreshToken, tokenType: tokenType, expiresOn: expiresOn as Date? ?? Date.distantPast, characterID: characterID, characterName: characterName, realm: realm, scopes: scopes)
			return token
		}
		set {
			guard let managedObjectContext = managedObjectContext else {return}
			
			if let token = newValue {
				if accessToken != token.accessToken {accessToken = token.accessToken}
				if refreshToken != token.refreshToken {refreshToken = token.refreshToken}
				if tokenType != token.tokenType {tokenType = token.tokenType}
				if characterID != token.characterID {characterID = token.characterID}
				if characterName != token.characterName {characterName = token.characterName}
				if realm != token.realm {realm = token.realm}
				if expiresOn != token.expiresOn {expiresOn = token.expiresOn}
				let newScopes = Set<String>(token.scopes)
				
				let toInsert: Set<String>
				if var scopes = self.scopes as? Set<Scope> {
					let toDelete = scopes.filter {
						guard let name = $0.name else {return true}
						return !newScopes.contains(name)
					}
					for scope in toDelete {
						managedObjectContext.delete(scope)
						scopes.remove(scope)
					}
					
					toInsert = newScopes.symmetricDifference(scopes.compactMap {return $0.name})
				}
				else {
					toInsert = newScopes
				}
				
				for name in toInsert {
					let scope = Scope(context: managedObjectContext)
					scope.name = name
					scope.account = self
				}
			}
		}
	}
	
	var activeSkillPlan: SkillPlan? {
		if let skillPlan = (try? managedObjectContext?.from(SkillPlan.self).filter(\SkillPlan.account == self && \SkillPlan.active == true).first()) ?? nil {
			return skillPlan
		}
		else if let skillPlan = skillPlans?.anyObject() as? SkillPlan {
			skillPlan.active = true
			return skillPlan
		}
		else if let managedObjectContext = managedObjectContext {
			let skillPlan = SkillPlan(context: managedObjectContext)
			skillPlan.active = true
			skillPlan.account = self
			skillPlan.name = NSLocalizedString("Default", comment: "")
			return skillPlan
		}
		else {
			return nil
		}
	}
}

struct Pair<A, B> {
	var a: A
	var b: B
	
	init(_ a: A, _ b: B) {
		self.a = a
		self.b = b
	}
}

extension Pair: Equatable where A: Equatable, B: Equatable {}
extension Pair: Hashable where A: Hashable, B: Hashable {}

extension SkillPlan {
	func add(_ trainingQueue: TrainingQueue) {
		let skills = self.skills?.allObjects as? [SkillPlanSkill]
		var position: Int32 = (skills?.map{$0.position}.max()).map{$0 + 1} ?? 0
		var queued = (skills?.map{Pair(Int($0.typeID), Int($0.level))}).map{Set($0)} ?? Set()
		
		for i in trainingQueue.queue {
			let key = Pair(i.skill.typeID, i.targetLevel)
			guard !queued.contains(key) else {continue}
			queued.insert(key)
			let skill = SkillPlanSkill(context: managedObjectContext!)
			skill.skillPlan = self
			skill.typeID = Int32(key.a)
			skill.level = Int16(key.b)
			skill.position = position
			position += 1
		}
	}
}
