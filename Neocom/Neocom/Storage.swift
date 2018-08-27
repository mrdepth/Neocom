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

protocol Storage {
	var viewContext: StorageContext {get}
	@discardableResult func performBackgroundTask<T>(_ block: @escaping (StorageContext) throws -> T) -> Future<T>
	@discardableResult func performBackgroundTask<T>(_ block: @escaping (StorageContext) throws -> Future<T>) -> Future<T>
}

protocol StorageContext: PersistentContext {
	func accounts() -> [Account]
	func account(with token: OAuth2Token) -> Account?
	func newAccount(with token: OAuth2Token) -> Account
	func currentAccount() -> Account?
}

class StorageContainer: Storage {
	
	lazy var viewContext: StorageContext = StorageContextBox(managedObjectContext: persistentContainer.viewContext)
	var persistentContainer: NSPersistentContainer
	
	init(persistentContainer: NSPersistentContainer? = nil) {
		self.persistentContainer = persistentContainer ?? {
			let container = NSPersistentContainer(name: "Storage", managedObjectModel: NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Storage", withExtension: "momd")!)!)
			
			let directory = URL.init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0])
			try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
			let url = directory.appendingPathComponent("store.sqlite")
			
			let description = NSPersistentStoreDescription()
			description.url = url
			description.type = CloudStoreType
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
			return container
		}()
	}
	
	
	@discardableResult
	func performBackgroundTask<T>(_ block: @escaping (StorageContext) throws -> T) -> Future<T> {
		let promise = Promise<T>()
		persistentContainer.performBackgroundTask { (context) in
			do {
				try promise.fulfill(block(StorageContextBox(managedObjectContext: context)))
			}
			catch {
				try? promise.fail(error)
			}
		}
		return promise.future
	}
	
	@discardableResult
	func performBackgroundTask<T>(_ block: @escaping (StorageContext) throws -> Future<T>) -> Future<T> {
		let promise = Promise<T>()
		
		persistentContainer.performBackgroundTask { (context) in
			do {
				try block(StorageContextBox(managedObjectContext: context)).then {
					try? promise.fulfill($0)
					}.catch {
						try? promise.fail($0)
				}
			}
			catch {
				try? promise.fail(error)
			}
		}
		return promise.future
	}
	
	static let shared = StorageContainer()
}

struct StorageContextBox: StorageContext {
	var managedObjectContext: NSManagedObjectContext
	
	func accounts() -> [Account] {
		return (try? managedObjectContext.from(Account.self).all()) ?? []
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
	
	func currentAccount() -> Account? {
		return accounts().first
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
}
