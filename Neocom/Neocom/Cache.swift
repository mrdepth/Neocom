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

protocol Cache: PersistentContainer where Context: CacheContext {
}

protocol CacheContext: PersistentContext {
}


class CachePersistentContainer: Cache {
	var persistentContainer = NSPersistentContainer(name: "Cache")
	lazy var viewContext: CacheContextBox = CacheContextBox(managedObjectContext: persistentContainer.viewContext)
	
	func performBackgroundTask<T>(_ block: @escaping (CacheContextBox) throws -> T) -> Future<T> {
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
}


struct CacheContextBox: CacheContext {
	var managedObjectContext: NSManagedObjectContext
}
