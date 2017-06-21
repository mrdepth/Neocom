//
//  NCManagedObjectObserver.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import CloudData

class NCManagedObjectObserver {
	typealias Handler =  (_ updated: Set<NSManagedObject>?, _ deleted:Set<NSManagedObject>?) -> Void
	let handler: Handler
	var objects = Set<NSManagedObject>()
	var observer: NotificationObserver?
	
	init(managedObjects: [NSManagedObject]? = nil, handler: @escaping Handler) {
		self.handler = handler
		self.objects = Set(managedObjects ?? [])
		
		observer = NotificationCenter.default.addNotificationObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: nil /*.main*/) { [weak self] (note) in
			guard let strongSelf = self else {return}
			
			let updates: Set<NSManagedObjectID>? = {
				guard let set = note.userInfo?[NSUpdatedObjectsKey] else {return nil}
				return set as? Set<NSManagedObjectID> ?? Set((set as? Set<NSManagedObject>)?.map {$0.objectID} ?? [])
			}()
			
			let updated = strongSelf.objects.filter { (object) -> Bool in
				return updates?.contains(object.objectID) == true
			}
			
			let deletes: Set<NSManagedObjectID>? = {
				guard let set = note.userInfo?[NSDeletedObjectsKey] else {return nil}
				return set as? Set<NSManagedObjectID> ?? Set((set as? Set<NSManagedObject>)?.map {$0.objectID} ?? [])
			}()

			let deleted = strongSelf.objects.filter { (object) -> Bool in
				return deletes?.contains(object.objectID) == true
			}

//			let updated = Set((note.userInfo?[NSUpdatedObjectsKey] as? Set<NSObject>)?.flatMap{ ($0 as? NSManagedObject)?.objectID ?? $0 as? NSManagedObjectID} ?? []).intersection(objects)
//			let deleted = Set((note.userInfo?[NSDeletedObjectsKey] as? Set<NSObject>)?.flatMap{ ($0 as? NSManagedObject)?.objectID ?? $0 as? NSManagedObjectID} ?? []).intersection(objects)
			
			//let updated = (note.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObjectID>)?.intersection(strongSelf.objectIDs)
			//let deleted = (note.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObjectID>)?.intersection(strongSelf.objectIDs)
			if !updated.isEmpty || !deleted.isEmpty {
				DispatchQueue.main.async {
					strongSelf.handler(Set(updated), Set(deleted))
				}
			}
		}
	}
	
	convenience init(managedObject: NSManagedObject, handler: @escaping Handler) {
		self.init(managedObjects: [managedObject], handler: handler)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(observer!)
	}

	func add(managedObject: NSManagedObject) {
		objects.insert(managedObject)
	}
	
	func remove(managedObject: NSManagedObject) {
		objects.remove(managedObject)
	}
	
}
