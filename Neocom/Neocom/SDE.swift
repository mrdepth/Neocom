//
//  SDE.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import Futures
import Expressible

protocol SDE: PersistentContainer where Context: SDEContext {
}

protocol SDEContext: PersistentContext {
	func invType(_ typeID: Int) -> SDEInvType?
	func invType(_ typeName: String) -> SDEInvType?
	func invGroup(_ groupID: Int) -> SDEInvGroup?
	func invCategory(_ categoryID: Int) -> SDEInvCategory?
	func invMetaGroup(_ metaGroupID: Int) -> SDEInvMetaGroup?
	func chrRace(_ raceID: Int) -> SDEChrRace?
	func chrBloodline(_ bloodlineID: Int) -> SDEChrBloodline?
	func chrAncestry(_ ancestryID: Int) -> SDEChrAncestry?
	func chrFaction(_ factionID: Int) -> SDEChrFaction?
	func ramActivity(_ activityID: Int) -> SDERamActivity?
	func eveIcon(_ file: String) -> SDEEveIcon?
	func dgmAttributeType(_ attributeID: Int) -> SDEDgmAttributeType?
	func mapSolarSystem(_ solarSystemID: Int) -> SDEMapSolarSystem?
	func mapConstellation(_ constellationID: Int) -> SDEMapConstellation?
	func mapRegion(_ regionID: Int) -> SDEMapRegion?
	func mapPlanet(_ planetID: Int) -> SDEMapPlanet?
	func staStation(_ stationID: Int) -> SDEStaStation?
}

class SDEPersistentContainer: SDE {
	lazy var viewContext: SDEContextBox = {
		var viewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator
		return SDEContextBox(managedObjectContext: viewContext)
	}()
	
	private(set) lazy var managedObjectModel: NSManagedObjectModel = {
		NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "SDE", withExtension: "momd")!)!
	}()

	private(set) lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		var persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
														   configurationName: nil,
														   at: Bundle.main.url(forResource: "SDE", withExtension: "sqlite"),
														   options: [NSReadOnlyPersistentStoreOption: true])
		return persistentStoreCoordinator
	}()
	
	init() {
		ValueTransformer.setValueTransformer(ImageValueTransformer(), forName: NSValueTransformerName("ImageValueTransformer"))
	}
	
	func performBackgroundTask<T>(_ block: @escaping (SDEContextBox) throws -> T) -> Future<T> {
		let promise = Promise<T>()

		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		context.persistentStoreCoordinator = persistentStoreCoordinator

		context.perform {
			do {
				try promise.fulfill(block(SDEContextBox(managedObjectContext: context)))
			}
			catch {
				try? promise.fail(error)
			}
		}
		return promise.future
	}
}


struct SDEContextBox: SDEContext {
	var managedObjectContext: NSManagedObjectContext
}

extension SDEContext {
	func invType(_ typeID: Int) -> SDEInvType? {
		return (try? self.managedObjectContext.from(SDEInvType.self).filter(\SDEInvType.typeID == Int32(typeID)).first()) ?? nil
	}
	
	func invType(_ typeName: String) -> SDEInvType? {
		return (try? self.managedObjectContext.from(SDEInvType.self).filter(\SDEInvType.typeName == typeName.caseInsensitive).first()) ?? nil
	}
	
	func invGroup(_ groupID: Int) -> SDEInvGroup? {
		return (try? self.managedObjectContext.from(SDEInvGroup.self).filter(\SDEInvGroup.groupID == Int32(groupID)).first()) ?? nil
	}
	
	func invCategory(_ categoryID: Int) -> SDEInvCategory? {
		return (try? self.managedObjectContext.from(SDEInvCategory.self).filter(\SDEInvCategory.categoryID == Int32(categoryID)).first()) ?? nil
	}
	
	func invMetaGroup(_ metaGroupID: Int) -> SDEInvMetaGroup? {
		return (try? self.managedObjectContext.from(SDEInvMetaGroup.self).filter(\SDEInvMetaGroup.metaGroupID == Int32(metaGroupID)).first()) ?? nil
	}
	
	func chrRace(_ raceID: Int) -> SDEChrRace? {
		return (try? self.managedObjectContext.from(SDEChrRace.self).filter(\SDEChrRace.raceID == Int32(raceID)).first()) ?? nil
	}
	
	func chrBloodline(_ bloodlineID: Int) -> SDEChrBloodline? {
		return (try? self.managedObjectContext.from(SDEChrBloodline.self).filter(\SDEChrBloodline.bloodlineID == Int32(bloodlineID)).first()) ?? nil
	}
	
	func chrAncestry(_ ancestryID: Int) -> SDEChrAncestry? {
		return (try? self.managedObjectContext.from(SDEChrAncestry.self).filter(\SDEChrAncestry.ancestryID == Int32(ancestryID)).first()) ?? nil
	}
	
	func chrFaction(_ factionID: Int) -> SDEChrFaction? {
		return (try? self.managedObjectContext.from(SDEChrFaction.self).filter(\SDEChrFaction.factionID == Int32(factionID)).first()) ?? nil
	}
	
	func ramActivity(_ activityID: Int) -> SDERamActivity? {
		return (try? self.managedObjectContext.from(SDERamActivity.self).filter(\SDERamActivity.activityID == Int32(activityID)).first()) ?? nil
	}
	
	func eveIcon(_ file: String) -> SDEEveIcon? {
		return (try? self.managedObjectContext.from(SDEEveIcon.self).filter(\SDEEveIcon.iconFile == file).first()) ?? nil
	}

	func eveIcon(_ name: SDEEveIcon.Name) -> SDEEveIcon? {
		return (try? self.managedObjectContext.from(SDEEveIcon.self).filter(\SDEEveIcon.iconFile == name.name).first()) ?? nil
	}

	func dgmAttributeType(_ attributeID: Int) -> SDEDgmAttributeType? {
		return (try? self.managedObjectContext.from(SDEDgmAttributeType.self).filter(\SDEDgmAttributeType.attributeID == Int32(attributeID)).first()) ?? nil
	}
	
	func mapSolarSystem(_ solarSystemID: Int) -> SDEMapSolarSystem? {
		return (try? self.managedObjectContext.from(SDEMapSolarSystem.self).filter(\SDEMapSolarSystem.solarSystemID == Int32(solarSystemID)).first()) ?? nil
	}
	
	func mapConstellation(_ constellationID: Int) -> SDEMapConstellation? {
		return (try? self.managedObjectContext.from(SDEMapConstellation.self).filter(\SDEMapConstellation.constellationID == Int32(constellationID)).first()) ?? nil
	}
	
	func mapRegion(_ regionID: Int) -> SDEMapRegion? {
		return (try? self.managedObjectContext.from(SDEMapRegion.self).filter(\SDEMapRegion.regionID == Int32(regionID)).first()) ?? nil
	}
	
	func mapPlanet(_ planetID: Int) -> SDEMapPlanet? {
		return (try? self.managedObjectContext.from(SDEMapPlanet.self).filter(\SDEMapPlanet.planetID == Int32(planetID)).first()) ?? nil
	}
	
	func staStation(_ stationID: Int) -> SDEStaStation? {
		return (try? self.managedObjectContext.from(SDEStaStation.self).filter(\SDEStaStation.stationID == Int32(stationID)).first()) ?? nil
	}

}

extension SDEInvType {
	subscript(key: SDEAttributeID) -> SDEDgmTypeAttribute? {
		return (try? self.managedObjectContext?.from(SDEDgmTypeAttribute.self).filter(\SDEDgmTypeAttribute.type == self && \SDEDgmTypeAttribute.attributeType?.attributeID == key.rawValue).first()) ?? nil
	}
}
