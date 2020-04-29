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
}
//
//
//
extension NSUserActivity {
    convenience init(fitting: FittingProject) throws {
        let data = try JSONEncoder().encode(fitting)
        self.init(activityType: NSUserActivityType.fitting)
        addUserInfoEntries(from: ["fitting": data])
    }
    
    func fitting(from managedObjectContext: NSManagedObjectContext) throws -> FittingProject {
        guard let data = userInfo?["fitting"] as? Data else {throw RuntimeError.invalidActivityType}
        let decoder = JSONDecoder()
        decoder.userInfo[FittingProject.managedObjectContextKey] = managedObjectContext
        return try decoder.decode(FittingProject.self, from: data)
    }
}
