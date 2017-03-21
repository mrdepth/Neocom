//
//  NCStorage.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import EVEAPI
import CloudData

class NCStorage: NSObject {
	private(set) lazy var managedObjectModel: NSManagedObjectModel = {
		NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "NCStorage", withExtension: "momd")!)!
	}()
	
	private(set) lazy var viewContext: NSManagedObjectContext = {
		var viewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator
		NotificationCenter.default.addObserver(self, selector: #selector(NCCache.managedObjectContextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
		return viewContext
	}()
	
	private(set) lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		var persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let directory = URL.init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0])
		try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
		var url = directory.appendingPathComponent("store.sqlite")
		
		for i in 0...1 {
			do {
				try persistentStoreCoordinator.addPersistentStore(ofType: CloudStoreType,
				                                                  configurationName: "Cloud",
				                                                  at: url,
				                                                  options: [CloudStoreOptions.recordZoneKey: "Neocom",
				                                                            CloudStoreOptions.binaryDataCompressionLevel: BinaryDataCompressionLevel.default])
				break
			} catch {
				try? FileManager.default.removeItem(at: url)
			}
		}
		
		url = directory.appendingPathComponent("local.sqlite")
		for i in 0...1 {
			do {
				try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
				                                                  configurationName: "Local",
				                                                  at: url,
				                                                  options: nil)
				break
			} catch {
				try? FileManager.default.removeItem(at: url)
			}
		}
		
		return persistentStoreCoordinator
	}()
	
	static let sharedStorage: NCStorage? = NCStorage()
	
	override init() {
		super.init()
		NotificationCenter.default.addObserver(self, selector: #selector(oauth2TokenDidRefresh(_:)), name: .OAuth2TokenDidRefresh, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		context.persistentStoreCoordinator = persistentStoreCoordinator
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.perform {
			block(context)
			if (context.hasChanges) {
				do {
					try context.save()
				}
				catch {
					print ("\(error)")
				}
			}
		}
	}
	
	func performTaskAndWait(_ block: @escaping (NSManagedObjectContext) -> Void) {
		let context = NSManagedObjectContext(concurrencyType: Thread.isMainThread ? .mainQueueConcurrencyType : .privateQueueConcurrencyType)
		context.persistentStoreCoordinator = persistentStoreCoordinator
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.performAndWait {
			block(context)
			if (context.hasChanges) {
				do {
					try context.save()
				}
				catch {
					print ("\(error)")
				}
			}
		}
	}
	
	private(set) lazy var accounts: NCFetchedCollection<NCAccount> = {
		return NCAccount.accounts(managedObjectContext: self.viewContext)
	}()

	
	//MARK: Private
	
	func managedObjectContextDidSave(_ notification: Notification) {
		guard let context = notification.object as? NSManagedObjectContext,
			viewContext !== context && context.persistentStoreCoordinator === viewContext.persistentStoreCoordinator
		else {
			return
		}
		viewContext.perform {
			self.viewContext.mergeChanges(fromContextDidSave: notification)
		}
	}
	
	func oauth2TokenDidRefresh(_ notification: Notification) {
		guard let token = notification.object as? OAuth2Token else {return}
		performBackgroundTask { managedObjectContext in
			let request = NSFetchRequest<NCAccount>(entityName: "Account")
			request.predicate = NSPredicate(format: "refreshToken == %@", token.refreshToken)
			guard let account = (try? managedObjectContext.fetch(request))?.last else {return}
			account.token = token
		}
	}
}
