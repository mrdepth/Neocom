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

protocol Cache {
	var viewContext: CacheContext {get}
	@discardableResult func performBackgroundTask<T>(_ block: @escaping (CacheContext) throws -> T) -> Future<T>
	@discardableResult func performBackgroundTask<T>(_ block: @escaping (CacheContext) throws -> Future<T>) -> Future<T>
	func newBackgroundContext() -> CacheContext
}

protocol CacheContext: PersistentContext {
	func sectionCollapseState<T: View>(identifier: String, scope: T.Type) -> SectionCollapseState?
	func newSectionCollapseState<T: View>(identifier: String, scope: T.Type) -> SectionCollapseState
	func price(for typeID: Int) -> Price?
	func price(for typeIDs: Set<Int>) -> [Int: Double]?
	func prices() -> [Price]?
	func contacts(with ids: Set<Int64>) -> [Int64: Contact]?
}


class CacheContainer: Cache {
	
	var persistentContainer: NSPersistentContainer
	
	init(persistentContainer: NSPersistentContainer? = nil) {
		self.persistentContainer = persistentContainer ?? {
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

			return container
		}()
	}
		
	lazy var viewContext: CacheContext = CacheContextBox(managedObjectContext: persistentContainer.viewContext)
	
	@discardableResult
	func performBackgroundTask<T>(_ block: @escaping (CacheContext) throws -> T) -> Future<T> {
		let promise = Promise<T>()
		persistentContainer.performBackgroundTask { (context) in
			do {
				let ctx = CacheContextBox(managedObjectContext: context)
				let result = try block(ctx)
				try ctx.save()
				try promise.fulfill(result)
			}
			catch {
				try? promise.fail(error)
			}
		}
		return promise.future
	}
	
	@discardableResult
	func performBackgroundTask<T>(_ block: @escaping (CacheContext) throws -> Future<T>) -> Future<T> {
		let promise = Promise<T>()
		
		persistentContainer.performBackgroundTask { (context) in
			do {
				let ctx = CacheContextBox(managedObjectContext: context)
				try block(ctx).then { result in
					ctx.managedObjectContext.perform {
						do {
							try ctx.save()
							try promise.fulfill(result)
						}
						catch {
							try? promise.fail(error)
						}
					}
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

	func newBackgroundContext() -> CacheContext {
		return CacheContextBox(managedObjectContext: persistentContainer.newBackgroundContext())
	}
}


struct CacheContextBox: CacheContext {
	
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
	
	
	var managedObjectContext: NSManagedObjectContext
	
}


extension Contact {
	var recipientType: ESI.Mail.Recipient.RecipientType? {
		return category.flatMap {ESI.Mail.Recipient.RecipientType(rawValue: $0)}
	}
}
