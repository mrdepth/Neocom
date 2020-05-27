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
import StoreKit
@_exported import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		ValueTransformer.setValueTransformer(ImageValueTransformer(), forName: NSValueTransformerName("ImageValueTransformer"))
        ValueTransformer.setValueTransformer(LoadoutTransformer(), forName: NSValueTransformerName(rawValue: "LoadoutTransformer"))
        ValueTransformer.setValueTransformer(NeocomSecureUnarchiveFromDataTransformer(), forName: NSValueTransformerName("NeocomSecureUnarchiveFromDataTransformer"))
		// Override point for customization after application launch.
        NotificationCenter.default.addObserver(self, selector: #selector(didRefreshToken(_:)), name: ESI.didRefreshTokenNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didInvalidateToken(_:)), name: ESI.didInvalidateTokenNotification, object: nil)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, nil) in
            DispatchQueue.main.async {
                self.notificationsManager = NotificationsManager(managedObjectContext: self.storage.persistentContainer.viewContext)
                UNUserNotificationCenter.current().delegate = self
            }
        }
        
        SKPaymentQueue.default().add(self)
        
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
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
    
    private var notificationsManager: NotificationsManager?
    lazy var storage = Storage()
    
    #if DEBUG

    lazy var testingAccount: Account? = {
        if let account = try? self.storage.persistentContainer.viewContext.from(Account.self).first() {
            if account.uuid == nil {
                account.uuid = "1"
                try? self.storage.persistentContainer.viewContext.save()
            }
            return account
        }
        else {
            let account = Account(token: oAuth2Token, context: self.storage.persistentContainer.viewContext)
            account.uuid = "1"
            try? self.storage.persistentContainer.viewContext.save()
            return account
        }
    }()
    
    #endif

    static var sharedDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return true
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        
    }
}


extension AppDelegate {
    @objc func didRefreshToken(_ note: Notification) {
        guard let token = note.userInfo?[ESI.tokenUserInfoKey] as? OAuth2Token else {return}
        DispatchQueue.main.async {
            let context = self.storage.persistentContainer.viewContext
            guard let accounts = try? context.from(Account.self).filter(/\Account.refreshToken == token.refreshToken).fetch() else {return}
            if accounts.isEmpty {
                let account = try? context.from(Account.self).filter(/\Account.characterID == token.characterID).first()
                account?.oAuth2Token = token
            }
            else {
                accounts.forEach{$0.oAuth2Token = token}
            }
        }
    }

    @objc func didInvalidateToken(_ note: Notification) {
//        guard let token = note.userInfo?[ESI.tokenUserInfoKey] as? OAuth2Token else {return}
    }

    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        defer { completionHandler() }
        guard let uuid = response.notification.request.content.userInfo["account"] as? String else {return}
        guard let account = try? storage.persistentContainer.viewContext.from(Account.self).filter(/\Account.uuid == uuid).first() else {return}
        guard let delegate = response.targetScene?.delegate as? SceneDelegate else {return}
        delegate.sharedState.account = account
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .badge, .alert])
    }
}

extension AppDelegate: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored, .failed:
                queue.finishTransaction(transaction)
                NotificationCenter.default.post(name: .didFinishPaymentTransaction, object: transaction)
            default:
                break
            }
        }
    }
}
