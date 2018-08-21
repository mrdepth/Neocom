//
//  PersistentContainer.swift
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
	func existingObject<T: NSManagedObject>(with objectID: NSManagedObjectID) throws -> T?
}

public protocol PersistentContainer {
	associatedtype Context: PersistentContext
	var viewContext: Context {get}
	@discardableResult func performBackgroundTask<T>(_ block: @escaping (Context) throws -> T) -> Future<T>
}

extension PersistentContext {
	func existingObject<T: NSManagedObject>(with objectID: NSManagedObjectID) throws -> T? {
		return (try? managedObjectContext.existingObject(with: objectID)) as? T
	}
}
