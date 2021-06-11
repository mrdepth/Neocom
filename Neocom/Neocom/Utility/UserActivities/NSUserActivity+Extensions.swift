//
//  NSUserActivity+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/23/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

enum NSUserActivityType {
    static let fitting = "\(bundleID).fitting.activity"
}

extension NSUserActivity {
    static let isMainWindowKey = "isMainWindow"
    static let loadoutKey = "loadout"
}
//
//
//
extension NSUserActivity {
    convenience init(fitting: FittingProject) throws {
        self.init(activityType: NSUserActivityType.fitting)
//        let data = try JSONEncoder().encode(fitting)
//        addUserInfoEntries(from: ["fitting": data])
    }
    
    func fitting(from managedObjectContext: NSManagedObjectContext) throws -> FittingProject {
        let project = FittingProject(fileURL: FittingProject.documentsDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension(Config.current.loadoutPathExtension),
                                     managedObjectContext: AppDelegate.sharedDelegate.storage.persistentContainer.viewContext)
        project.restoreUserActivityState(self)
        guard project.gang != nil || project.structure != nil else {throw RuntimeError.invalidLoadoutFormat}
        return project
//        guard let data = userInfo?["fitting"] as? Data else {throw RuntimeError.invalidActivityType}
//        let decoder = JSONDecoder()
//        decoder.userInfo[FittingProject.managedObjectContextKey] = managedObjectContext
//        return try decoder.decode(FittingProject.self, from: data)
    }
}
