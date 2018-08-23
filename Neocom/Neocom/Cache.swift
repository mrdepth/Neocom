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
	func record(identifier: String, account: String?) -> CacheRecord?
	func newRecord(identifier: String, account: String?) -> CacheRecord
}


class CacheContainer: Cache {
	
	var persistentContainer: NSPersistentContainer
	
	init(persistentContainer: NSPersistentContainer? = nil) {
		self.persistentContainer = persistentContainer ?? {
			let container = NSPersistentContainer(name: "Cache")
			container.loadPersistentStores { (description, _) in
				if let url = description.url {
					try? FileManager.default.removeItem(at: url)
					container.loadPersistentStores{ (_, error) in
						if let error = error {
							print(error)
						}
					}
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

	static let shared = CacheContainer()
}



struct CacheContextBox: CacheContext {
	
	func record(identifier: String, account: String?) -> CacheRecord? {
		return (try? managedObjectContext.from(CacheRecord.self).filter(\CacheRecord.account == account && \CacheRecord.identifier == identifier).first()) ?? nil
	}
	
	func newRecord(identifier: String, account: String?) -> CacheRecord {
		
		let record = CacheRecord(context: managedObjectContext)
		record.account = account
		record.identifier = identifier
		record.data = CacheRecordData(context: managedObjectContext)
		return record
	}

	var managedObjectContext: NSManagedObjectContext
	
}


extension CacheRecord {
	
	func getValue<T: Codable>() -> T? {
		return data?.value.flatMap{(try? JSONDecoder().decode([T].self, from: $0).first) ?? nil}
	}
	
	func setValue<T: Codable>(_ value: T?) {
		data?.value = value.flatMap {try? JSONEncoder().encode([$0])}
	}
	
	var isExpired: Bool {
		guard let cachedUntil = cachedUntil else {return true}
		guard data?.value != nil else {return true}
		return cachedUntil <= Date()
	}
}
