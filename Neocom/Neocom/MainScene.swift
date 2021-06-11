//
//  MainScene.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/2/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct MainScene: Scene {
    let storage: Storage
    let sharedState: SharedState
    
    var body: some Scene {
        WindowGroup {
            Main()
                .modifier(ServicesViewModifier(managedObjectContext: storage.persistentContainer.viewContext, backgroundManagedObjectContext: storage.persistentContainer.newBackgroundContext(), sharedState: sharedState))
                .environmentObject(storage)
        }
    }
}

