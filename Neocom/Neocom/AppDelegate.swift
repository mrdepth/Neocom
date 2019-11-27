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
@_exported import UIKit

//1554561480

#if DEBUG
fileprivate let oAuth2Token = try! JSONDecoder().decode(OAuth2Token.self, from: "{\"scopes\":[\"esi-calendar.respond_calendar_events.v1\",\"esi-calendar.read_calendar_events.v1\",\"esi-location.read_location.v1\",\"esi-location.read_ship_type.v1\",\"esi-mail.organize_mail.v1\",\"esi-mail.read_mail.v1\",\"esi-mail.send_mail.v1\",\"esi-skills.read_skills.v1\",\"esi-skills.read_skillqueue.v1\",\"esi-wallet.read_character_wallet.v1\",\"esi-search.search_structures.v1\",\"esi-clones.read_clones.v1\",\"esi-universe.read_structures.v1\",\"esi-killmails.read_killmails.v1\",\"esi-assets.read_assets.v1\",\"esi-planets.manage_planets.v1\",\"esi-fittings.read_fittings.v1\",\"esi-fittings.write_fittings.v1\",\"esi-markets.structure_markets.v1\",\"esi-characters.read_loyalty.v1\",\"esi-characters.read_standings.v1\",\"esi-industry.read_character_jobs.v1\",\"esi-markets.read_character_orders.v1\",\"esi-characters.read_blueprints.v1\",\"esi-contracts.read_character_contracts.v1\",\"esi-clones.read_implants.v1\",\"esi-killmails.read_corporation_killmails.v1\",\"esi-wallet.read_corporation_wallets.v1\",\"esi-corporations.read_divisions.v1\",\"esi-assets.read_corporation_assets.v1\",\"esi-corporations.read_blueprints.v1\",\"esi-contracts.read_corporation_contracts.v1\",\"esi-industry.read_corporation_jobs.v1\",\"esi-markets.read_corporation_orders.v1\"],\"characterID\":1554561480,\"characterName\":\"Artem Valiant\",\"refreshToken\":\"1ETZtnu7-ic9k1vE-rhBGhC76QQ5VMCbzKU3bIid32BgS00pgtOJPozLGaUSociDGpnyzpPLMapm3bOvbjERA0wUYPvNMmr77HPdrJtFh09kII7VN5SxvaVKYO9PkokE4GByoWY8ExmiQadXLmy5yzzJx4BkvI4mobv82MG7LZzbil8n4rH23bSOnVQGOuzBAgZflvwAEqdKw1y8Gm8PAlnoDjnb_B0LM2bBrvYz7zY1\",\"tokenType\":\"Bearer\",\"expiresOn\":556720099.51404095,\"accessToken\":\"YWm0r6Z1svq2Jido_8zHQ5bIo6TE72CmvI-TR8-9_VLgZd6plowi6r9OzQyC4_DzIImjAbhyRGSMz3Hv_6Z6kg2\",\"realm\":\"esi\"}".data(using: .utf8)!)
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		ValueTransformer.setValueTransformer(ImageValueTransformer(), forName: NSValueTransformerName("ImageValueTransformer"))
		
		// Override point for customization after application launch.
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
        return NSManagedObjectModel(byMerging: [storageModel, sdeModel])!
    }

    lazy var storageContainer: NSPersistentCloudKitContainer = {
        
        let container = NSPersistentCloudKitContainer(name: "Neocom", managedObjectModel: managedObjectModel)
        let sde = NSPersistentStoreDescription(url: Bundle.main.url(forResource: "SDE", withExtension: "sqlite")!)
        sde.configuration = "SDE"
        sde.isReadOnly = true
        sde.shouldMigrateStoreAutomatically = false
        
        let storage = NSPersistentStoreDescription(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!).appendingPathComponent("stora.sqlite"))
        storage.configuration = "Storage"
        container.persistentStoreDescriptions = [sde, storage]
        container.loadPersistentStores { (_, error) in
            if let error = error {
                print(error)
            }
        }
        return container
    }()
    
    #if DEBUG
    lazy var testingContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Neocom", managedObjectModel: managedObjectModel)
        let sde = NSPersistentStoreDescription(url: Bundle.main.url(forResource: "SDE", withExtension: "sqlite")!)
        sde.configuration = "SDE"
        sde.isReadOnly = true
        sde.shouldMigrateStoreAutomatically = false
        
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("stora.sqlite")
        try? FileManager.default.removeItem(at: url)
        
        let storage = NSPersistentStoreDescription(url: url)
        storage.configuration = "Storage"
        container.persistentStoreDescriptions = [sde, storage]
        container.loadPersistentStores { (_, error) in
            if let error = error {
                print(error)
            }
        }
        _ = Account(token: oAuth2Token, context: container.viewContext)
        try? container.viewContext.save()
        return container
    }()
    
    static var sharedDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    #endif
}

