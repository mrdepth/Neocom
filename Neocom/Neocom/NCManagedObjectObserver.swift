//
//  NCManagedObjectObserver.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

class NCManagedObjectObserver {
	typealias Handler =  (_ updated: Set<NSManagedObjectID>?, _ deleted:Set<NSManagedObjectID>?) -> Void
	let handler: Handler
	var objectIDs = Set<NSManagedObjectID>()
	var observer: NSObjectProtocol?
	
	init(managedObjectID: NSManagedObjectID? = nil, handler: @escaping Handler) {
		self.handler = handler
		if let managedObjectID = managedObjectID {
			objectIDs.insert(managedObjectID)
		}
		
		observer = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: .main) { [weak self] (note) in
			guard let strongSelf = self else {return}
			
			let updated = (note.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObjectID>)?.intersection(strongSelf.objectIDs)
			let deleted = (note.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObjectID>)?.intersection(strongSelf.objectIDs)
			if updated?.count ?? 0 > 0 || deleted?.count ?? 0 > 0 {
				DispatchQueue.main.async {
					strongSelf.handler(updated, deleted)
				}
			}
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(observer!)
	}

	func add(managedObjectID: NSManagedObjectID) {
		objectIDs.insert(managedObjectID)
	}
	
	func remove(managedObjectID: NSManagedObjectID) {
		objectIDs.remove(managedObjectID)
	}
	
}
