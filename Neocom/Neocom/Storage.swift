//
//  Storage.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CloudData
import CoreData
import Futures

protocol Storage: PersistentContainer where Context: StorageContext {
	
}

protocol StorageContext: PersistentContext {
	
}

class StorageContainer: Storage {
	lazy var viewContext: StorageContextBox = {
		var viewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator
		return StorageContextBox(managedObjectContext: viewContext)
	}()
	
	private(set) lazy var managedObjectModel: NSManagedObjectModel = {
		NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Storage", withExtension: "momd")!)!
	}()
	
	private(set) lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		var persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		
		let directory = URL.init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0])
		try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
		var url = directory.appendingPathComponent("store.sqlite")

		
		func add() throws {
			try persistentStoreCoordinator.addPersistentStore(ofType: CloudStoreType,
															  configurationName: nil,
															  at: url,
															  options: [CloudStoreOptions.recordZoneKey: "Neocom",
																		CloudStoreOptions.binaryDataCompressionAlgorithm: CompressionAlgorithm.zlib(.default),
																		CloudStoreOptions.mergePolicyType: NSMergePolicyType.overwriteMergePolicyType])
		}
		
		do {
			try add()
		} catch {
			try? FileManager.default.removeItem(at: url)
			try? add()
		}
		
		return persistentStoreCoordinator
	}()
	
	
	func performBackgroundTask<T>(_ block: @escaping (StorageContextBox) throws -> T) -> Future<T> {
		let promise = Promise<T>()
		
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		context.persistentStoreCoordinator = persistentStoreCoordinator
		
		context.perform {
			do {
				try promise.fulfill(block(StorageContextBox(managedObjectContext: context)))
			}
			catch {
				try? promise.fail(error)
			}
		}
		return promise.future
	}
}

struct StorageContextBox: StorageContext {
	var managedObjectContext: NSManagedObjectContext
}
