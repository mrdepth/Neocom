//
//  AppDelegate.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI
import Expressible
import Combine
import SwiftUI
@_exported import UIKit



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		ValueTransformer.setValueTransformer(ImageValueTransformer(), forName: NSValueTransformerName("ImageValueTransformer"))
        ValueTransformer.setValueTransformer(LoadoutTransformer(), forName: NSValueTransformerName(rawValue: "LoadoutTransformer"))
		// Override point for customization after application launch.
        NotificationCenter.default.addObserver(self, selector: #selector(didRefreshToken(_:)), name: ESI.didRefreshTokenNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didInvalidateToken(_:)), name: ESI.didInvalidateTokenNotification, object: nil)
        
		return true
	}
    
	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}
    
    var managedObjectModel: NSManagedObjectModel {
        let storageModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Storage", withExtension: "momd")!)!
        let sdeModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "SDE", withExtension: "momd")!)!
        let cacheModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Cache", withExtension: "momd")!)!
        return NSManagedObjectModel(byMerging: [storageModel, sdeModel, cacheModel])!
    }
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
//        migrate()
        let container = NSPersistentCloudKitContainer(name: "Neocom", managedObjectModel: managedObjectModel)
        let sde = NSPersistentStoreDescription(url: Bundle.main.url(forResource: "SDE", withExtension: "sqlite")!)
        sde.configuration = "SDE"
        sde.isReadOnly = true
        sde.shouldMigrateStoreAutomatically = false
        
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
//        #if DEBUG
//        try? FileManager.default.removeItem(at: baseURL.appendingPathComponent("store.sqlite"))
//        try? FileManager.default.removeItem(at: baseURL.appendingPathComponent("cache.sqlite"))
//        #endif
        
        let storage = NSPersistentStoreDescription(url: baseURL.appendingPathComponent("store.sqlite"))
        storage.configuration = "Storage"
        
        let cache = NSPersistentStoreDescription(url: baseURL.appendingPathComponent("cache.sqlite"))
        cache.configuration = "Cache"

        container.persistentStoreDescriptions = [sde, storage, cache]
        container.loadPersistentStores { (_, error) in
            if let error = error {
                print(error)
            }
        }
        
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                #if DEBUG
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                #endif
            }
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
    
    #if DEBUG

    lazy var testingAccount: Account? = {
        if let account = try? self.persistentContainer.viewContext.from(Account.self).first() {
            if account.uuid == nil {
                account.uuid = "1"
                try? self.persistentContainer.viewContext.save()
            }
            return account
        }
        else {
            let account = Account(token: oAuth2Token, context: self.persistentContainer.viewContext)
            account.uuid = "1"
            try? self.persistentContainer.viewContext.save()
            return account
        }
    }()
    
    static var sharedDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    #endif
}


extension AppDelegate {
    @objc func didRefreshToken(_ note: Notification) {
        guard let token = note.userInfo?[ESI.tokenUserInfoKey] as? OAuth2Token else {return}
        DispatchQueue.main.async {
            guard let accounts = try? self.persistentContainer.viewContext.from(Account.self).filter(/\Account.refreshToken == token.refreshToken).fetch() else {return}
            accounts.forEach{$0.oAuth2Token = token}
        }
    }

    @objc func didInvalidateToken(_ note: Notification) {
//        guard let token = note.userInfo?[ESI.tokenUserInfoKey] as? OAuth2Token else {return}
    }

    
}
