//
//  NCDatabase.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCDatabase {
	private(set) lazy var managedObjectModel: NSManagedObjectModel = {
		NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "NCDatabase", withExtension: "momd")!)!
	}()
	
	private(set) lazy var viewContext: NSManagedObjectContext = {
		var viewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator
		return viewContext
	}()
	
	private(set) lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		var persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
		                                                   configurationName: nil,
		                                                   at: Bundle.main.url(forResource: "NCDatabase", withExtension: "sqlite"),
		                                                   options: [NSReadOnlyPersistentStoreOption: true])
		return persistentStoreCoordinator
	}()

	static let sharedDatabase: NCDatabase? = NCDatabase()

	init() {
	}
	
	func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		context.persistentStoreCoordinator = persistentStoreCoordinator
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.perform {
			block(context)
		}
	}

	func performTaskAndWait(_ block: @escaping (NSManagedObjectContext) -> Void) {
		let context = NSManagedObjectContext(concurrencyType: Thread.isMainThread ? .mainQueueConcurrencyType : .privateQueueConcurrencyType)
		context.persistentStoreCoordinator = persistentStoreCoordinator
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.performAndWait {
			block(context)
		}
	}
	
	private(set) lazy var invTypes: NCFetchedCollection<NCDBInvType> = {
		return NCDBInvType.invTypes(managedObjectContext: self.viewContext)
	}()
}

extension NCDBInvType {
	class func invTypes(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBInvType> {
		return NCFetchedCollection<NCDBInvType>(entityName: "InvType", predicateFormat: "typeID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
	
	var allAttributes: NCFetchedCollection<NCDBDgmTypeAttribute> {
		get {
			return NCFetchedCollection<NCDBDgmTypeAttribute>(entityName: "DgmTypeAttribute", predicateFormat: "type == %@ AND attributeType.attributeID == %@", argumentArray: [self], managedObjectContext: self.managedObjectContext!)
		}
	}
}
