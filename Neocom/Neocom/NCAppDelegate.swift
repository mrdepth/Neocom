//
//  NCAppDelegate.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData
import CloudData
import SafariServices
import StoreKit
import Firebase
import FBSDKCoreKit
import Appodeal

@UIApplicationMain
class NCAppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:
		[UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert], categories: nil))
		application.registerForRemoteNotifications()

		NSPersistentStoreCoordinator.registerStoreClass(CloudStore.self, forStoreType: CloudStoreType)
//		let directory = URL.init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]).appendingPathComponent("com.shimanski.eveuniverse.NCCache")
//		let url = directory.appendingPathComponent("store.sqlite")
//		try? FileManager.default.removeItem(at: url)

		
		setupAppearance()
		
		FirebaseApp.configure()
		FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
		
		#if DEBUG
			Appodeal.setTestingEnabled(true)
		#endif
		Appodeal.setLocationTracking(false)
		Appodeal.initialize(withApiKey: NCApoodealKey, types: [.banner])

		SKPaymentQueue.default().add(self)
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		if let context = NCCache.sharedCache?.viewContext, context.hasChanges {
			try? context.save()
		}
		
		let task = application.beginBackgroundTask(expirationHandler: nil)
		
		NCNotificationManager.sharedManager.schedule { _ in
			application.endBackgroundTask(task)
		}
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		if products == nil && productsRequest == nil {
			let request = SKProductsRequest(productIdentifiers: Set(InAppProductID.all.map{$0.rawValue}))
			request.delegate = self
			request.start()
			productsRequest = request
		}
		FBSDKAppEvents.activateApp()
		NCDataManager().updateMarketPrices()

		DispatchQueue.global(qos: .background).async {
			autoreleasepool {
				let fileManager = FileManager.default
				guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.shimanski.neocom") else {return}
				let flagURL = groupURL.appendingPathComponent(".already_transferred")
				if !fileManager.fileExists(atPath: flagURL.path) {
					let loadoutsURL = groupURL.appendingPathComponent("loadouts.xml")
					guard let data = try? Data(contentsOf: loadoutsURL),
						let loadouts = NCLoadoutRepresentation(value: data) else {return}
					DispatchQueue.main.async {
						guard let topMostController = self.window?.rootViewController?.topMostPresentedViewController else {return}
						if !((topMostController as? UINavigationController)?.viewControllers.first is NCTransferViewController) {
							Router.Utility.Transfer(loadouts: loadouts).perform(source: topMostController, sender: nil)
						}
					}
				}
			}
		}

		if #available(iOS 10.3, *) {
			let defaults = UserDefaults.standard
			if let firstLaunchDate = defaults.object(forKey: UserDefaults.Key.NCFirstLaunchDate) as? Date {
				if let lastReviewDate = defaults.object(forKey: UserDefaults.Key.NCLastReviewDate) as? Date {
					if lastReviewDate.timeIntervalSinceNow < -TimeInterval.NCReviewTimeInterval {
						SKStoreReviewController.requestReview()
						defaults.set(Date(), forKey: UserDefaults.Key.NCLastReviewDate)
					}
				}
				else {
					if firstLaunchDate.timeIntervalSinceNow < -TimeInterval.NCFirstReviewTime {
						SKStoreReviewController.requestReview()
						defaults.set(Date(), forKey: UserDefaults.Key.NCLastReviewDate)
					}
				}
			}
			else {
				defaults.set(Date(), forKey: UserDefaults.Key.NCFirstLaunchDate)
			}
		}

	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		
		
		
		if OAuth2.handleOpenURL(url, clientID: ESClientID, secretKey: ESSecretKey, completionHandler: { (result) in
			switch result {
			case let .success(token):
				guard let context = NCStorage.sharedStorage?.viewContext else {break}
				
				let account: NCAccount = context.fetch("Account", limit: 1, where: "characterID == %qi", token.characterID) ?? {
					let account = NCAccount(entity: NSEntityDescription.entity(forEntityName: "Account", in: context)!, insertInto: context)
					account.uuid = UUID().uuidString
					return account
				}()
				account.token = token
				
				if context.hasChanges {
					try? context.save()
				}
				let request = NSFetchRequest<NCAccount>(entityName: "Account")
				if let result = try? context.fetch(request), result.count == 1 {
					NCAccount.current = result.first
				}
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
		else if let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let scheme = components.scheme?.lowercased() {
			
			switch NCURLScheme(rawValue: scheme) {
			case .showinfo?:
				guard let path = components.path.components(separatedBy: "/").first else {return false}
				guard let typeID = Int(path) else {return false}
				return showTypeInfo(typeID: typeID)
			case .fitting?:
				return showFitting(dna: components.path)
			case .nc?:
				switch components.host {
				case "account"?:
					guard let uuid = components.queryItems?.first(where: {$0.name == "uuid"})?.value else {return false}
					guard let account = NCStorage.sharedStorage?.accounts[uuid] else {return false}
					NCAccount.current = account
					return true
				default:
					return false
				}
			default:
				return false
			}
		}
		else {
			return false
		}
	}
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		CloudStore.handleRemoteNotification(userInfo: userInfo)
		completionHandler(.newData)
	}
	
	func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
		let size = UIScreen.main.bounds.size
		return window?.traitCollection.userInterfaceIdiom == .pad || min(size.width, size.height) > 400 ? [.all] : [.portrait]
	}
	
	//MARK: Private
	
	var products: [SKProduct]?
	private var productsRequest: SKProductsRequest?

	private func setupAppearance() {
		CSScheme.currentScheme = CSScheme.Dark
		let navigationBar = UINavigationBar.appearance(whenContainedInInstancesOf: [NCNavigationController.self])
		navigationBar.setBackgroundImage(UIImage.image(color: UIColor.background), for: UIBarMetrics.default)
		navigationBar.shadowImage = UIImage.image(color: UIColor.background)
		navigationBar.barTintColor = UIColor.background
		navigationBar.tintColor = UIColor.white
		navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
		navigationBar.barStyle = .black
		navigationBar.isTranslucent = false
		let tableView = NCTableView.appearance()
		tableView.tableBackgroundColor = UIColor.background
		tableView.separatorColor = UIColor.separator
		NCTableViewCell.appearance().backgroundColor = UIColor.cellBackground
		NCHeaderTableViewCell.appearance().backgroundColor = UIColor.background
		NCBackgroundView.appearance().backgroundColor = UIColor.background
		
		let searchBar = UISearchBar.appearance(whenContainedInInstancesOf: [NCTableView.self])
		searchBar.barTintColor = UIColor.background
		searchBar.tintColor = UIColor.white
		searchBar.setSearchFieldBackgroundImage(UIImage.searchFieldBackgroundImage(color: UIColor.separator), for: UIControlState.normal)
//		searchBar.backgroundImage = UIImage.image(color: UIColor.background)
		
		let toolbar = UIToolbar.appearance(whenContainedInInstancesOf: [NCNavigationController.self])
		toolbar.tintColor = UIColor.white
		toolbar.barStyle = .black
		toolbar.barTintColor = UIColor.background
		toolbar.isTranslucent = false
	}

}

extension NCAppDelegate {
	
	fileprivate func showTypeInfo(typeID: Int) -> Bool {
		guard let type = NCDatabase.sharedDatabase?.invTypes[typeID] else {return false}
		guard let controller = (window?.rootViewController as? UISplitViewController)?.viewControllers.last?.topMostPresentedViewController else {return false}
		
		guard !(controller is UIAlertController) else {return false}
		Router.Database.TypeInfo(type, kind: .push).perform(source: controller, sender: nil)
		return true
	}
	
	fileprivate func showFitting(dna: String) -> Bool {
		guard let controller = (window?.rootViewController as? UISplitViewController)?.viewControllers.last?.topMostPresentedViewController else {return false}
		guard !(controller is UIAlertController) else {return false}

		guard let loadout = NCLoadoutRepresentation(value: dna) else {return false}
		
		Router.Fitting.Editor(representation: loadout).perform(source: controller, sender: nil)
		return true
	}
}

extension NCAppDelegate: SKPaymentTransactionObserver {
	func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		transactions.forEach { transaction in
			switch transaction.transactionState {
			case .purchased:
				if let product = products?.first(where: {$0.productIdentifier == transaction.payment.productIdentifier}) {
					APDSdk.shared().track(inAppPurchase: product.price, currency: product.priceLocale.currencyCode ?? "USD")
				}
				else if let price = InAppProductID(rawValue: transaction.payment.productIdentifier)?.price {
					APDSdk.shared().track(inAppPurchase: NSNumber(value: price.0), currency: price.1)
				}
				queue.finishTransaction(transaction)
			case .failed, .restored:
				queue.finishTransaction(transaction)
			default:
				break
			}
		}
	}
}

extension NCAppDelegate: SKProductsRequestDelegate {
	public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
		products = response.products
	}
}
