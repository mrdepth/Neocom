//
//  SDE.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

class SDE: NSPersistentContainer {
	init() {
		let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "SDE", withExtension: "momd")!)!
		super.init(name: "SDE", managedObjectModel: model)
		let description = NSPersistentStoreDescription()
		description.url = Bundle.main.url(forResource: "SDE", withExtension: "sqlite")
		description.isReadOnly = true
		persistentStoreDescriptions = [description]
	}
}
