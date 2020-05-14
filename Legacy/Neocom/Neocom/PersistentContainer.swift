//
//  PersistentContainer.swift
//  Neocom
//
//  Created by Artem Shimanski on 13/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import CloudData
import Futures

class PersistentContainer<Context: PersistentContext> {
	lazy var viewContext: Context = Context(managedObjectContext: persistentContainer.viewContext)
	var persistentContainer: NSPersistentContainer
	
	init(persistentContainer: NSPersistentContainer) {
		self.persistentContainer = persistentContainer
	}
	
	func managedObjectID(forURIRepresentation url: URL) -> NSManagedObjectID? {
		return persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url)
	}
	
	@discardableResult
	func performBackgroundTask<T>(_ block: @escaping (Context) throws -> T) -> Future<T> {
		let promise = Promise<T>()
		persistentContainer.performBackgroundTask { (context) in
			do {
				let ctx = Context(managedObjectContext: context)
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
	func performBackgroundTask<T>(_ block: @escaping (Context) throws -> Future<T>) -> Future<T> {
		let promise = Promise<T>()
		
		persistentContainer.performBackgroundTask { (context) in
			do {
				let ctx = Context(managedObjectContext: context)
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
	
	func newBackgroundContext() -> Context {
		return Context(managedObjectContext: persistentContainer.newBackgroundContext())
	}
}
