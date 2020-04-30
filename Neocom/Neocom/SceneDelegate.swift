//
//  SceneDelegate.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import UIKit
import SwiftUI
import CoreData
import Expressible
import EVEAPI
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

    private var currentActivities: [AnyUserActivityProvider] = []
    private var isMainWindow: Bool = false
    private var sharedState = SharedState(managedObjectContext: AppDelegate.sharedDelegate.persistentContainer.viewContext)
    private var subscriptions = Set<AnyCancellable>()

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

		// Create the SwiftUI view that provides the window contents.
//        let contentView = ContentView()
		// Use a UIHostingController as window root view controller.
        
        let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
        let rootModifier = ServicesViewModifier(managedObjectContext: AppDelegate.sharedDelegate.persistentContainer.viewContext,
                                                backgroundManagedObjectContext: AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext(),
                                                sharedState: self.sharedState)

        func makeMainWindow(_ window: UIWindow, _ project: FittingProject?) {
            isMainWindow = true
            let contentView = Main(restoredFitting: project)
                .modifier(rootModifier)
                .onPreferenceChange(AppendPreferenceKey<AnyUserActivityProvider, AnyUserActivityProvider>.self) { [weak self] activities in
                    self?.currentActivities = activities
            }

            window.rootViewController = UIHostingController(rootView: contentView)
        }
        
        func makeChildWindow(_ window: UIWindow, _ project: FittingProject) {
            isMainWindow = false
            let contentView = NavigationView {
                FittingEditor(project: project).environmentObject(FittingAutosaver(project: project))
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .modifier(rootModifier)
//            .onPreferenceChange(AppendPreferenceKey<AnyUserActivityProvider, AnyUserActivityProvider>.self) { [weak self] activities in
//                self?.currentActivities = activities
//            }
            currentActivities = [AnyUserActivityProvider(project)]
            window.rootViewController = UIHostingController(rootView: contentView)
        }
        
		if let windowScene = scene as? UIWindowScene {
		    let window = UIWindow(windowScene: windowScene)
            
            if let activity = connectionOptions.userActivities.first(where: {$0.activityType == NSUserActivityType.fitting}), let project = try? activity.fitting(from: context) {
                
                if UIApplication.shared.supportsMultipleScenes {
                    makeChildWindow(window, project)
                }
                else {
                    makeMainWindow(window, project)
                }
                
            }
            else if let activity = session.stateRestorationActivity, activity.activityType == NSUserActivityType.fitting, let project = try? activity.fitting(from: context) {
                if activity.userInfo?[NSUserActivity.isMainWindowKey] as? Bool == false {
                    makeChildWindow(window, project)
                }
                else {
                    makeMainWindow(window, project)
                }
            }
            else {
                makeMainWindow(window, nil)
            }

		    self.window = window
		    window.makeKeyAndVisible()
		}
        
        sharedState.$userActivity.assign(to: \.userActivity , on: scene).store(in: &subscriptions)
	}

	func sceneDidDisconnect(_ scene: UIScene) {
        subscriptions.removeAll()
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
	}
    
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        scene.userActivity
    }

	func sceneWillResignActive(_ scene: UIScene) {
//        scene.userActivity = sharedState.userActivity
//        scene.userActivity = currentActivities.last?.userActivity()
//        scene.userActivity?.addUserInfoEntries(from: [NSUserActivity.isMainWindowKey: isMainWindow])
//        scene.userActivity = state.flatMap{try? NSUserActivity(state: $0)}
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
        AppDelegate.sharedDelegate.saveContext()
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.
	}
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            if OAuth2.handleOpenURL(context.url, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey, completionHandler: { (result) in
                
                let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
                switch result {
                case let .success(token):
                    let data = try? JSONEncoder().encode(token)
                    let s = String(data: data!, encoding: .utf8)
                    print(s)
                    if let account = try? context.from(Account.self).filter(/\Account.characterID == token.characterID).first() {
                        account.oAuth2Token = token
                    }
                    else {
                        let account = Account(context: context)
                        account.oAuth2Token = token
                        account.uuid = UUID().uuidString
                    }
                    if context.hasChanges {
                        try? context.save()
                    }
                    
                case let .failure(error):
                    //                let controller = self.window?.rootViewController?.topMostPresentedViewController
                    //                controller?.present(UIAlertController(error: error), animated: true, completion: nil)
                    break
                }
            }) {
                //            if let controller = self.window?.rootViewController?.topMostPresentedViewController as? SFSafariViewController {
                //                controller.dismiss(animated: true, completion: nil)
                //            }
            }
            
        }
        print(URLContexts)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityType.fitting {
            if UIApplication.shared.supportsMultipleScenes {
                UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil, errorHandler: nil)
            }
            else {
                let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
                guard let fitting = try? userActivity.fitting(from: context) else {return}
                guard let root = window?.rootViewController, let topController = sequence(first: root, next: {$0.presentedViewController}).reversed().first else {return}

                let view = NavigationView {
                    FittingEditor(project: fitting) { [weak topController] in
                        topController?.dismiss(animated: true, completion: nil)
                    }.environmentObject(FittingAutosaver(project: fitting))
                }.modifier(ServicesViewModifier(managedObjectContext: context, backgroundManagedObjectContext: AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext(), sharedState: sharedState))
                topController.present(UIHostingController(rootView: view), animated: true, completion: nil)
            }
        }
    }
    
    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) {
        
    }
    
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
    }
    
    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
    }
}

