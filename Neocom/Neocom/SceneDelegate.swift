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
import SafariServices

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

    private var currentActivities: [AnyUserActivityProvider] = []
    private var isMainWindow: Bool = false
//    let storage = Storage()
    lazy var sharedState: SharedState = SharedState(managedObjectContext: self.storage.persistentContainer.viewContext)
    private var subscriptions = Set<AnyCancellable>()
    var storage: Storage {
        (UIApplication.shared.delegate as! AppDelegate).storage
    }
    
    @UserDefault(key: .latestLaunchedVersion) var latestLaunchedVersion = ""

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let context = storage.persistentContainer.viewContext
        let rootModifier = ServicesViewModifier(managedObjectContext: storage.persistentContainer.viewContext,
                                                backgroundManagedObjectContext: storage.persistentContainer.newBackgroundContext(),
                                                sharedState: self.sharedState)

        func makeMainWindow(_ window: UIWindow, _ project: FittingProject?) {
            isMainWindow = true
            let contentView = Main(restoredFitting: project)
                .modifier(rootModifier)
                .environmentObject(storage)
                .onPreferenceChange(AppendPreferenceKey<AnyUserActivityProvider, AnyUserActivityProvider>.self) { [weak self] activities in
                    self?.currentActivities = activities
            }

            window.rootViewController = UIHostingController(rootView: contentView)
        }
        
        func makeChildWindow(_ window: UIWindow, _ project: FittingProject) {
            isMainWindow = false
            let contentView = NavigationView {
                FittingEditor(project: project)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .modifier(rootModifier)
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
            
            if !showTutorialIfNeeded() {
                downloadLanguagePackIfNeeded()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .didFinishStartup, object: nil)
                }
            }
		}
        sharedState.$userActivity.assign(to: \.userActivity , on: scene).store(in: &subscriptions)
        latestLaunchedVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
	}
    
    private func showTutorialIfNeeded() -> Bool {
        guard latestLaunchedVersion.isEmpty else {return false}
        guard let window = self.window else {return false}
        guard let controller = window.rootViewController?.topMostPresentedViewController else {return false}
        
        let view = Tutorial {
            controller.dismiss(animated: true, completion: nil)
        }.modifier(ServicesViewModifier(managedObjectContext: storage.persistentContainer.viewContext, backgroundManagedObjectContext: storage.persistentContainer.newBackgroundContext(), sharedState: sharedState))
        .environmentObject(storage)
        let tutorial = TutorialViewController(rootView: view)
        tutorial.modalPresentationStyle = .formSheet
        
        controller.present(tutorial, animated: true, completion: nil)
        
        return true
    }
    
    private func downloadLanguagePackIfNeeded() {
        guard let window = self.window else {return}
        
        let sde = storage.sde
        
        if !sde.isAvailable() {
            let controller = window.rootViewController?.topMostPresentedViewController
            
            var isCancelled = false

            let view = NavigationView {
                LanguagePacks { _ in
                    isCancelled = true
                }
                    .navigationBarItems(leading: BarButtonItems.close { [weak controller] in
                        isCancelled = true
                        self.storage.sde = BundleResource(tag: LanguageID.default.rawValue)
                        controller?.dismiss(animated: true, completion: nil)
                    })
            }.modifier(ServicesViewModifier(managedObjectContext: storage.persistentContainer.viewContext, backgroundManagedObjectContext: storage.persistentContainer.newBackgroundContext(), sharedState: sharedState))
            
            sde.beginAccessingResource { [weak controller] (error) in
                DispatchQueue.main.async {
                    guard !isCancelled else {return}
                    if error == nil {
                        self.storage.sde = sde
                    }
                    controller?.dismiss(animated: true, completion: nil)
                }
            }
            let vc = UIHostingController(rootView: view)
            vc.modalPresentationStyle = .formSheet
            controller?.present(vc, animated: false, completion: nil)
        }
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
        storage.saveContext()
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.
	}
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            let isOAuth2 = OAuth2.handleOpenURL(context.url, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey, completionHandler: { (result) in
                let context = self.storage.persistentContainer.viewContext
                switch result {
                case let .success(token):
                    let vc = self.window?.rootViewController?.topMostPresentedViewController
                    if vc is SFSafariViewController {
                        vc?.dismiss(animated: true, completion: nil)
                    }
                    //                    let data = try? JSONEncoder().encode(token)
                    //                    let s = String(data: data!, encoding: .utf8)
                    //                    print(s)
                    if let account = try? context.from(Account.self).filter(/\Account.characterID == token.characterID).first() {
                        account.oAuth2Token = token
                        self.sharedState.account = account
                    }
                    else {
                        let account = Account(context: context)
                        account.oAuth2Token = token
                        account.uuid = UUID().uuidString
                        self.sharedState.account = account
                    }
                    if context.hasChanges {
                        try? context.save()
                    }
                case let .failure(error):
                    let controller = self.window?.rootViewController?.topMostPresentedViewController
                    controller?.present(UIAlertController(error: error), animated: true, completion: nil)
                }
            })
            
            if !isOAuth2 {
                guard let components = URLComponents(url: context.url, resolvingAgainstBaseURL: false), let scheme = components.scheme?.lowercased() else {return}
                
                switch scheme {
                case URLScheme.showinfo:
                    guard let path = components.path.components(separatedBy: "/").first else {break}
                    guard let typeID = Int(path) else {break}
                    return showTypeInfo(typeID: typeID)
                case URLScheme.fitting:
                    let dna = components.path
                    guard let project = try? FittingProject(dna: dna, skillLevels: .level(5), managedObjectContext: storage.persistentContainer.viewContext) else {break}
                    
                    if let activity = project.userActivity, UIApplication.shared.supportsMultipleScenes && OpenMode.default.openInNewWindow {
                        project.updateUserActivityState(activity)
                        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
                    }
                    else {
                        openFitting(fitting: project)
                    }

                default:
                    break
                }
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
                let context = storage.persistentContainer.viewContext
                guard let fitting = try? userActivity.fitting(from: context) else {return}
                openFitting(fitting: fitting)
            }
        }
    }
    
    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) {
        
    }
    
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
    }
    
    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
    }
    
    private func showTypeInfo(typeID: Int) {
        let container = storage.persistentContainer
        guard let controller = window?.rootViewController?.topMostPresentedViewController else {return}
        guard let type = try? container.viewContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(typeID)).first() else {return}
        
        let view = NavigationView {
            TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close { [weak controller] in
                controller?.dismiss(animated: true, completion: nil)
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .modifier(ServicesViewModifier(managedObjectContext: container.viewContext, backgroundManagedObjectContext: container.newBackgroundContext(), sharedState: sharedState))
        
        controller.present(UIHostingController(rootView: view), animated: true, completion: nil)
    }
    
    private func openFitting(fitting: FittingProject) {
        let container = storage.persistentContainer
        guard let controller = window?.rootViewController?.topMostPresentedViewController else {return}
        
        let view = NavigationView {
            FittingEditor(project: fitting) { [weak controller] in
                controller?.dismiss(animated: true, completion: nil)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .modifier(ServicesViewModifier(managedObjectContext: container.viewContext, backgroundManagedObjectContext: container.newBackgroundContext(), sharedState: sharedState))
        
        controller.present(UIHostingController(rootView: view), animated: true, completion: nil)
    }
}

