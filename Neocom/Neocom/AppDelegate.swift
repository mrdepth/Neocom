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
import EVEAPI
import SafariServices

#if DEBUG
var isTesting: Bool = CommandLine.arguments.contains("-testing")
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?
	
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		NSSetUncaughtExceptionHandler { (exc) in
			print(exc)
		}
		setupAppearance()
		setupServices()
		return true
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		NSPersistentStoreCoordinator.registerStoreClass(CloudStore.self, forStoreType: CloudStoreType)
		
		
		#if DEBUG
		if isTesting {
			window?.rootViewController = UIViewController()
		}
		#endif
		return true
	}
}


extension AppDelegate {
	
	fileprivate func setupServices() {
		Services.sde = SDE()
		Services.settings = Settings()

		func common() {
			Services.cache = Cache.default()
			Services.storage = Storage.default()
			Services.api = APIService()
			Services.userDefaults = UserDefaults.standard
		}
		
		#if DEBUG
		if isTesting {
			Services.cache = Cache.testing()
			Services.storage = Storage.testing()
			Services.api = APIServiceTesting()
			Services.userDefaults = UserDefaults(suiteName: "testing")
		}
		else {
			common()
		}
		#else
		common()
		#endif
	}
	
	fileprivate func setupAppearance() {
		CSScheme.currentScheme = CSScheme.Dark
		
		let navigationBar = UINavigationBar.appearance(whenContainedInInstancesOf: [NavigationController.self])
		navigationBar.setBackgroundImage(UIImage.image(color: UIColor.background), for: UIBarMetrics.default)
		navigationBar.shadowImage = UIImage.image(color: UIColor.background)
		navigationBar.barTintColor = UIColor.background
		navigationBar.tintColor = UIColor.white
		navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
		navigationBar.barStyle = .black
		navigationBar.isTranslucent = false

		
		TableView.appearance().tableBackgroundColor = .background
		TableView.appearance().separatorColor = .separator
		RowCell.appearance().backgroundColor = .cellBackground
		HeaderCell.appearance().backgroundColor = .background
		BackgroundView.appearance().backgroundColor = .background
		
		let searchBar = UISearchBar.appearance(whenContainedInInstancesOf: [TableView.self])
		searchBar.barTintColor = .background
		searchBar.tintColor = .white
		searchBar.setSearchFieldBackgroundImage(UIImage.searchFieldBackgroundImage(color: .separator), for: UIControl.State.normal)

		let toolbar = UIToolbar.appearance(whenContainedInInstancesOf: [NavigationController.self])
		toolbar.tintColor = .white
		toolbar.barStyle = .black
		toolbar.barTintColor = .background
		toolbar.isTranslucent = false

	}
}


extension AppDelegate {
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		
		if OAuth2.handleOpenURL(url, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey, completionHandler: { (result) in
			switch result {
			case let .success(token):
				
				if let account = Services.storage.viewContext.account(with: token) {
					account.oAuth2Token = token
				}
				else {
					let account = Services.storage.viewContext.newAccount(with: token)
				}
				try? Services.storage.viewContext.save()

			case let .failure(error):
				let controller = self.window?.rootViewController?.topMostPresentedViewController
				controller?.present(UIAlertController(error: error), animated: true, completion: nil)
				break
			}
		}) {
			if let controller = self.window?.rootViewController?.topMostPresentedViewController as? SFSafariViewController {
				controller.dismiss(animated: true, completion: nil)
			}
			
			return true
		}
		else {
			return false
		}
	}
}
