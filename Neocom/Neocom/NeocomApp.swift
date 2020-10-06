//
//  NeocomApp.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/1/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
@_exported import UIKit

@main
struct NeocomApp: App {
    let storage: Storage
    let state: SharedState
    
    init() {
        self.storage = Storage()
        self.state = SharedState(managedObjectContext: storage.persistentContainer.viewContext)
    }
    
    var body: some Scene {
        MainScene(storage: storage, sharedState: state)
    }
}
