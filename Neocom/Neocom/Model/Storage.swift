//
//  Storage.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

class Storage: NSPersistentContainer {
    init() {
        let storageModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Storage", withExtension: "momd")!)!
        let sdeModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "SDE", withExtension: "momd")!)!
        let model = NSManagedObjectModel(byMerging: [storageModel, sdeModel])!
        
        super.init(name: "Storage", managedObjectModel: model)
        let sde = NSPersistentStoreDescription()
        sde.url = Bundle.main.url(forResource: "SDE", withExtension: "sqlite")
        sde.configuration = "SDE"
        sde.isReadOnly = true
        sde.shouldMigrateStoreAutomatically = false
        
        let storage = NSPersistentStoreDescription()
        storage.configuration = "Storage"
        storage.url = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!).appendingPathComponent("stora.sqlite")
        persistentStoreDescriptions = [sde, storage]
    }
}


public class LoadoutDescription: NSObject {
	
}

public class ImplantSetDescription: NSObject {
	
}

public class FleetDescription: NSObject {
	
}
