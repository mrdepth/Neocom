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

protocol SDE {
	var viewContext: SDEContext {get}
	@discardableResult func performBackgroundTask<T>(_ block: @escaping (SDEContext) throws -> T) -> Future<T>
	@discardableResult func performBackgroundTask<T>(_ block: @escaping (SDEContext) throws -> Future<T>) -> Future<T>
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

class SDEContainer: SDE {
	lazy var viewContext: SDEContext = SDEContextBox(managedObjectContext: persistentContainer.viewContext)
	var persistentContainer: NSPersistentContainer
	
	init(persistentContainer: NSPersistentContainer? = nil) {
		ValueTransformer.setValueTransformer(ImageValueTransformer(), forName: NSValueTransformerName("ImageValueTransformer"))

		self.persistentContainer = persistentContainer ?? {
			let container = NSPersistentContainer(name: "SDE", managedObjectModel: NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "SDE", withExtension: "momd")!)!)
			
			let description = NSPersistentStoreDescription()
			description.url = Bundle.main.url(forResource: "SDE", withExtension: "sqlite")
			description.isReadOnly = true
			container.persistentStoreDescriptions = [description]
			container.loadPersistentStores { (_, _) in
			}
			return container
		}()
	}
	
	
	@discardableResult
	func performBackgroundTask<T>(_ block: @escaping (SDEContext) throws -> T) -> Future<T> {
		let promise = Promise<T>()
		persistentContainer.performBackgroundTask { (context) in
			do {
				try promise.fulfill(block(SDEContextBox(managedObjectContext: context)))
			}
			catch {
				try? promise.fail(error)
			}
		}
		return promise.future
	}
	
	@discardableResult
	func performBackgroundTask<T>(_ block: @escaping (SDEContext) throws -> Future<T>) -> Future<T> {
		let promise = Promise<T>()
		
		persistentContainer.performBackgroundTask { (context) in
			do {
				try block(SDEContextBox(managedObjectContext: context)).then {
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
	
//	static let shared = SDEContainer()
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

extension SDEWhType {
	@objc var targetSystemClassDisplayName: String? {
		switch targetSystemClass {
		case 0:
			return NSLocalizedString("Exit WH", comment: "")
		case 1...6:
			return String(format: NSLocalizedString("W-Space Class %d", comment: ""), targetSystemClass)
		case 7:
			return NSLocalizedString("High-Sec", comment: "")
		case 8:
			return NSLocalizedString("Low-Sec", comment: "")
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
