//
//  NCAppDelegate.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI


@UIApplicationMain
class NCAppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:
		[UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		setupAppearance()
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}

	private func setupAppearance() {
		CSScheme.currentScheme = CSScheme.Dark
		let navigationBar = UINavigationBar.appearance(whenContainedInInstancesOf: [NCNavigationController.self])
		navigationBar.setBackgroundImage(UIImage.image(color: UIColor.background), for: UIBarMetrics.default)
		navigationBar.shadowImage = UIImage.image(color: UIColor.background)
		navigationBar.barTintColor = UIColor.background
		let tableView = NCTableView.appearance()
		tableView.backgroundColor = UIColor.background
		tableView.separatorColor = UIColor.separator
		NCTableViewCell.appearance().backgroundColor = UIColor.cellBackground
		NCTableViewHeaderCell.appearance().backgroundColor = UIColor.background
		NCBackgroundView.appearance().backgroundColor = UIColor.background
		
		let searchBar = UISearchBar.appearance(whenContainedInInstancesOf: [NCTableView.self])
		searchBar.barTintColor = UIColor.background
		searchBar.tintColor = UIColor.white
		searchBar.setSearchFieldBackgroundImage(UIImage.searchFieldBackgroundImage(color: UIColor.separator), for: UIControlState.normal)
		searchBar.backgroundImage = UIImage.image(color: UIColor.background)
	}

}

