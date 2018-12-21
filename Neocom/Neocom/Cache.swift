//
//  Cache.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import Futures
import Expressible
import EVEAPI

class Cache: PersistentContainer<CacheContext> {
	
	class func `default`() -> Cache {
		let container = NSPersistentContainer(name: "Cache")
		var isLoaded = false
		container.loadPersistentStores { (_, error) in
			isLoaded = error == nil
		}
		
		if !isLoaded, let url = container.persistentStoreDescriptions.first?.url {
			try? FileManager.default.removeItem(at: url)
			container.loadPersistentStores { (_, _) in
			}
		}
		return Cache(persistentContainer: container)
	}
	
	#if DEBUG
	class func testing() -> Cache {
		let container = NSPersistentContainer(name: "Cache", managedObjectModel: NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Cache", withExtension: "momd")!)!)
		let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Cache.sqlite")
		try? FileManager.default.removeItem(at: url)
		
		let description = NSPersistentStoreDescription()
		description.url = url
		container.persistentStoreDescriptions = [description]
		container.loadPersistentStores { (description, error) in
			if let error = error {
				fatalError(error.localizedDescription)
			}
		}
		return Cache(persistentContainer: container)
	}
	#endif
}


struct CacheContext: PersistentContext {
	var managedObjectContext: NSManagedObjectContext

	func sectionCollapseState<T: View>(identifier: String, scope: T.Type) -> SectionCollapseState? {
		let scope = "\(scope)"
		return (try? managedObjectContext.from(SectionCollapseState.self).filter(\SectionCollapseState.scope == scope && \SectionCollapseState.identifier == identifier).first()) ?? nil
	}

	func newSectionCollapseState<T: View>(identifier: String, scope: T.Type) -> SectionCollapseState {
		let scope = "\(scope)"
		let state = SectionCollapseState(context: managedObjectContext)
		state.scope = scope
		state.identifier = identifier
		return state
	}
	
	func price(for typeID: Int) -> Price? {
		return (try? managedObjectContext.from(Price.self).filter(\Price.typeID == typeID).first()) ?? nil
	}
	
	func price(for typeIDs: Set<Int>) -> [Int: Double]? {
		guard let prices = (try? managedObjectContext.from(Price.self).filter((\Price.typeID).in(typeIDs)).all()) ?? nil else {return nil}
		return Dictionary(prices.map{(Int($0.typeID), $0.price)}, uniquingKeysWith: {lhs, _ in lhs})
	}
	
	func prices() -> [Price]? {
		return (try? managedObjectContext.from(Price.self).all()) ?? nil
	}
	
	func contacts(with ids: Set<Int64>) -> [Int64: Contact]? {
		let request = managedObjectContext
			.from(Contact.self)
			.filter((\Contact.contactID).in(ids))
		return try? Dictionary(request.all().map {($0.contactID, $0)}, uniquingKeysWith: { (a, _) in a})
	}
	
	func typePickerRecent(category: SDEDgmppItemCategory, type: SDEInvType) -> TypePickerRecent {
		let recent = (try? managedObjectContext
			.from(TypePickerRecent.self)
			.filter(\TypePickerRecent.category == category.category && \TypePickerRecent.subcategory == category.subcategory && \TypePickerRecent.raceID == category.race?.raceID ?? 0 && \TypePickerRecent.typeID == type.typeID)
			.first()) ?? nil
		return recent ?? {
			let recent = TypePickerRecent(context: managedObjectContext)
			recent.category = category.category
			recent.subcategory = category.subcategory
			recent.raceID = category.race?.raceID ?? 0
			recent.typeID = type.typeID
			return recent

		}()
	}
}


extension Contact {
	var recipientType: ESI.Mail.Recipient.RecipientType? {
		return category.flatMap {ESI.Mail.Recipient.RecipientType(rawValue: $0)}
	}
}
