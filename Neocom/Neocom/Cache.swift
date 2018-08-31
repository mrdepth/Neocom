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

protocol Cache {
	var viewContext: CacheContext {get}
	@discardableResult func performBackgroundTask<T>(_ block: @escaping (CacheContext) throws -> T) -> Future<T>
	@discardableResult func performBackgroundTask<T>(_ block: @escaping (CacheContext) throws -> Future<T>) -> Future<T>
}

protocol CacheContext: PersistentContext {
	func sectionCollapseState<T: View>(identifier: String, scope: T.Type) -> SectionCollapseState?
	func newSectionCollapseState<T: View>(identifier: String, scope: T.Type) -> SectionCollapseState
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
				try promise.fulfill(block(CacheContextBox(managedObjectContext: context)))
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
				try block(CacheContextBox(managedObjectContext: context)).then {
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

//	static let shared = CacheContainer()
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
	
	var managedObjectContext: NSManagedObjectContext
	
}

