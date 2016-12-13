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
		ValueTransformer.setValueTransformer(NCDBImageValueTransformer(), forName: NSValueTransformerName("NCDBImageValueTransformer"))
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
	
	private(set) lazy var eveIcons: NCFetchedCollection<NCDBEveIcon> = {
		return NCDBEveIcon.eveIcons(managedObjectContext: self.viewContext)
	}()

	private(set) lazy var mapSolarSystems: NCFetchedCollection<NCDBMapSolarSystem> = {
		return NCDBMapSolarSystem.mapSolarSystems(managedObjectContext: self.viewContext)
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

extension NCDBInvGroup {
	class func invGroups(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBInvGroup> {
		return NCFetchedCollection<NCDBInvGroup>(entityName: "InvGroup", predicateFormat: "groupID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}

extension NCDBEveIcon {
	class func eveIcons(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBEveIcon> {
		return NCFetchedCollection<NCDBEveIcon>(entityName: "EveIcon", predicateFormat: "iconFile == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
	
	class func icon(file: String) -> NCDBEveIcon? {
		return NCDatabase.sharedDatabase?.eveIcons[file]
	}
	
	class var defaultCategory: NCDBEveIcon {
		return defaultGroup
	}

	class var defaultGroup: NCDBEveIcon {
		return icon(file: "38_174")!
	}

	class var defaultType: NCDBEveIcon {
		return icon(file: "07_15")!
	}
}

extension NCDBDgmAttributeType {
	class func dgmAttributeTypes(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBDgmAttributeType> {
		return NCFetchedCollection<NCDBDgmAttributeType>(entityName: "DgmAttributeType", predicateFormat: "attributeID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}

extension NCDBMapSolarSystem {
	class func mapSolarSystems(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBMapSolarSystem> {
		return NCFetchedCollection<NCDBMapSolarSystem>(entityName: "MapSolarSystem", predicateFormat: "solarSystemID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}
