//
//  PersistentContext.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import Futures

public protocol PersistentContext {
	var managedObjectContext: NSManagedObjectContext {get}
//	func existingObject<T: NSManagedObject>(with objectID: NSManagedObjectID) throws -> T?
//	func save() throws -> Void
//	func performAndWait<T>(_ block: () throws -> T) throws -> T
//	func performAndWait<T>(_ block: () -> T) -> T
//	@discardableResult func perform<T>(_ block: @escaping () throws -> T) -> Future<T>
	
	init(managedObjectContext: NSManagedObjectContext)
}

extension PersistentContext {
	func existingObject<T: NSManagedObject>(with objectID: NSManagedObjectID) throws -> T {
		let value = (try managedObjectContext.existingObject(with: objectID))
		guard let result = value as? T else { throw NCError.castError(from: type(of: value), to: T.self) }
		return result
	}
	
	func save() throws -> Void {
		if managedObjectContext.hasChanges {
			try managedObjectContext.save()
		}
	}
	
	func performAndWait<T>(_ block: () throws -> T) throws -> T {
		var result: T?
		var err: Error?
		managedObjectContext.performAndWait {
			do {
				result = try block()
			}
			catch {
				err = error
			}
		}
		if let error = err {
			throw error
		}
		return result!
	}
	
	func performAndWait<T>(_ block: () -> T) -> T {
		var result: T?
		managedObjectContext.performAndWait {
			result = block()
		}
		return result!
	}
	
	@discardableResult
	func perform<T>(_ block: @escaping () throws -> T) -> Future<T> {
		let promise = Promise<T>()
		managedObjectContext.perform {
			do {
				let result = try block()
				try self.save()
				try promise.fulfill(result)
			}
			catch {
				try? promise.fail(error)
			}
		}
		return promise.future
	}
	
	@discardableResult
	func perform<T>(_ block: @escaping () throws -> Future<T>) -> Future<T> {
		let promise = Promise<T>()
		
		managedObjectContext.perform {
			do {
				try block().then { result in
					self.managedObjectContext.perform {
						do {
							try self.save()
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
}
