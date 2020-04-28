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
    static let restorableState = "\(bundleID).restorableState"
}

//extension NSUserActivity {
//    static let openInNewWindowKey = "openInNewWindow"
//}
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
    
    convenience init(state: RestorableState) throws {
        let data = try JSONEncoder().encode(state)
        self.init(activityType: NSUserActivityType.restorableState)
        addUserInfoEntries(from: ["state": data])
    }
    
    func restorableState(from managedObjectContext: NSManagedObjectContext) throws -> RestorableState {
        guard let data = userInfo?["state"] as? Data else {throw RuntimeError.invalidActivityType}
        let decoder = JSONDecoder()
        decoder.userInfo[FittingProject.managedObjectContextKey] = managedObjectContext
        return try decoder.decode(RestorableState.self, from: data)
    }
}

class RestorableState: ObservableObject, Codable {
    struct Navigation: RawRepresentable, Identifiable, Hashable {
        let rawValue: String
        
        var id: String {
            return rawValue
        }
    }
    
    @Published var main: Navigation?
    @Published var selectedFitting: FittingProject?
    
    init() {}
    
    enum CodingKeys: String, CodingKey {
        case main
        case selectedFitting
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        main = try container.decodeIfPresent(String.self, forKey: .main).flatMap{RestorableState.Navigation(rawValue: $0)}
        selectedFitting = try container.decodeIfPresent(FittingProject.self, forKey: .selectedFitting)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(main?.rawValue, forKey: .main)
        try container.encodeIfPresent(selectedFitting, forKey: .selectedFitting)
    }
}
