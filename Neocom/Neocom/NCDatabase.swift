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

	func performTaskAndWait<T: Any>(_ block: @escaping (NSManagedObjectContext) -> T) -> T {
		let context = NSManagedObjectContext(concurrencyType: Thread.isMainThread ? .mainQueueConcurrencyType : .privateQueueConcurrencyType)
		context.persistentStoreCoordinator = persistentStoreCoordinator
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		var v: T?
		context.performAndWait {
			v = block(context)
		}
		return v!
	}
	
	private(set) lazy var invTypes: NCFetchedCollection<NCDBInvType> = {
		return NCDBInvType.invTypes(managedObjectContext: self.viewContext)
	}()

	private(set) lazy var invCategories: NCFetchedCollection<NCDBInvCategory> = {
		return NCDBInvCategory.invCategories(managedObjectContext: self.viewContext)
	}()

	private(set) lazy var invGroups: NCFetchedCollection<NCDBInvGroup> = {
		return NCDBInvGroup.invGroups(managedObjectContext: self.viewContext)
	}()
	
	private(set) lazy var eveIcons: NCFetchedCollection<NCDBEveIcon> = {
		return NCDBEveIcon.eveIcons(managedObjectContext: self.viewContext)
	}()

	private(set) lazy var mapSolarSystems: NCFetchedCollection<NCDBMapSolarSystem> = {
		return NCDBMapSolarSystem.mapSolarSystems(managedObjectContext: self.viewContext)
	}()

	private(set) lazy var mapConstellations: NCFetchedCollection<NCDBMapConstellation> = {
		return NCDBMapConstellation.mapConstellations(managedObjectContext: self.viewContext)
	}()

	private(set) lazy var mapRegions: NCFetchedCollection<NCDBMapRegion> = {
		return NCDBMapRegion.mapRegions(managedObjectContext: self.viewContext)
	}()

	private(set) lazy var staStations: NCFetchedCollection<NCDBStaStation> = {
		return NCDBStaStation.staStations(managedObjectContext: self.viewContext)
	}()

	private(set) lazy var mapDenormalize: NCFetchedCollection<NCDBMapDenormalize> = {
		return NCDBMapDenormalize.mapDenormalize(managedObjectContext: self.viewContext)
	}()
	
	private(set) lazy var invMetaGroups: NCFetchedCollection<NCDBInvMetaGroup> = {
		return NCDBInvMetaGroup.invMetaGroups(managedObjectContext: self.viewContext)
	}()
	
	private(set) lazy var chrRaces: NCFetchedCollection<NCDBChrRace> = {
		return NCDBChrRace.chrRaces(managedObjectContext: self.viewContext)
	}()

	private(set) lazy var chrFactions: NCFetchedCollection<NCDBChrFaction> = {
		return NCDBChrFaction.chrFactions(managedObjectContext: self.viewContext)
	}()

	private(set) lazy var ramActivities: NCFetchedCollection<NCDBRamActivity> = {
		return NCDBRamActivity.ramActivities(managedObjectContext: self.viewContext)
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

extension NCDBInvCategory {
	class func invCategories(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBInvCategory> {
		return NCFetchedCollection<NCDBInvCategory>(entityName: "InvCategory", predicateFormat: "categoryID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
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
	
	class func icon(masteryLevel: Int?) -> NCDBEveIcon? {
		guard let masteryLevel = masteryLevel else {return icon(file: "79_01")}
		guard (0...4).contains(masteryLevel) else {return nil}
		return icon(file: "07_\(masteryLevel + 2)")
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

extension NCDBMapConstellation {
	class func mapConstellations(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBMapConstellation> {
		return NCFetchedCollection<NCDBMapConstellation>(entityName: "MapConstellation", predicateFormat: "constellationID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}


extension NCDBMapRegion {
	class func mapRegions(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBMapRegion> {
		return NCFetchedCollection<NCDBMapRegion>(entityName: "MapRegion", predicateFormat: "regionID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}

extension NCDBStaStation {
	class func staStations(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBStaStation> {
		return NCFetchedCollection<NCDBStaStation>(entityName: "StaStation", predicateFormat: "stationID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}

extension NCDBMapDenormalize {
	class func mapDenormalize(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBMapDenormalize> {
		return NCFetchedCollection<NCDBMapDenormalize>(entityName: "MapDenormalize", predicateFormat: "itemID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}

extension NCDBDgmppItemCategory {
	class func category(categoryID: NCDBDgmppItemCategoryID, subcategory: Int? = nil, race: NCDBChrRace? = nil) -> NCDBDgmppItemCategory? {
		let request = NSFetchRequest<NCDBDgmppItemCategory>(entityName: "DgmppItemCategory")
		var predicates = [NSPredicate]()
		predicates.append(NSPredicate(format: "category == %d", categoryID.rawValue))
		if let subcategory = subcategory {
			predicates.append(NSPredicate(format: "subcategory == %d", subcategory))
		}
		if let race = race {
			predicates.append(NSPredicate(format: "race == %@", race))
		}
		request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
		request.fetchLimit = 1
		return (try? NCDatabase.sharedDatabase?.viewContext.fetch(request))??.first
	}
}

extension NCDBInvMetaGroup {
	class func invMetaGroups(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBInvMetaGroup> {
		return NCFetchedCollection<NCDBInvMetaGroup>(entityName: "InvMetaGroup", predicateFormat: "metaGroupID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}

extension NCDBChrRace {
	class func chrRaces(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBChrRace> {
		return NCFetchedCollection<NCDBChrRace>(entityName: "ChrRace", predicateFormat: "raceID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}

extension NCDBChrFaction {
	class func chrFactions(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBChrFaction> {
		return NCFetchedCollection<NCDBChrFaction>(entityName: "ChrFaction", predicateFormat: "factionID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}

extension NCDBRamActivity {
	class func ramActivities(managedObjectContext: NSManagedObjectContext) -> NCFetchedCollection<NCDBRamActivity> {
		return NCFetchedCollection<NCDBRamActivity>(entityName: "RamActivity", predicateFormat: "activityID == %@", argumentArray: [], managedObjectContext: managedObjectContext)
	}
}

extension NCDBWhType {
	
	var targetSystemClassDisplayName: String? {
		switch targetSystemClass {
		case 0:
			return NSLocalizedString("Exit WH", comment: "")
		case 1...6:
			return String(format: NSLocalizedString("W-Space Class %d", comment: ""), targetSystemClass)
		case 7:
			return NSLocalizedString("High-sec", comment: "")
		case 8:
			return NSLocalizedString("Low-sec", comment: "")
		case 9:
			return NSLocalizedString("0.0 System", comment: "")
		case 12:
			return NSLocalizedString("Thera", comment: "")
		case 13:
			return NSLocalizedString("W-Frig", comment: "")
		default:
			return String(format: NSLocalizedString("Unknown Class %d", comment: ""), targetSystemClass)
		}
	}
}
