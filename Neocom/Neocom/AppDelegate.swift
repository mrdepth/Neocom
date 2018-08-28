//
//  AppDelegate.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Appodeal
import CoreData
import CloudData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		NSPersistentStoreCoordinator.registerStoreClass(CloudStore.self, forStoreType: CloudStoreType)
		
		setupAppearance()
		return true
	}
}


extension AppDelegate {
	fileprivate func setupAppearance() {
		TableView.appearance().tableBackgroundColor = .background
		TableView.appearance().separatorColor = .separator
		RowCell.appearance().backgroundColor = .cellBackground
		HeaderCell.appearance().backgroundColor = .background
	}
}
