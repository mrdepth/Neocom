//
//  AdvertisingProvider.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
import Foundation
import SwiftUI
import Combine
import Appodeal
import StackConsentManager


/// Advertising interface that provides published state
/// which can be used in SwiftUI
final class AdvertisingProvider: NSObject, ObservableObject {
    // MARK: Types and definitions
    private typealias SynchroniseConsentCompletion = () -> Void
    
    /// APDBannerView SwiftUI interface
    struct Banner: UIViewRepresentable {
        typealias UIViewType = APDBannerView
        
        func makeUIView(context: UIViewRepresentableContext<Banner>) -> APDBannerView {
            // Use shared banner view to
            return AdvertisingProvider.shared.bannerView
        }
        
        func updateUIView(_ uiView: APDBannerView, context: UIViewRepresentableContext<Banner>) {
            uiView.rootViewController = UIApplication.shared.rootViewController
        }
    }
    
    // MARK: Stored properties
    /// Singleton object of provider
    static let shared: AdvertisingProvider = AdvertisingProvider()
    
    private var synchroniseConsentCompletion: SynchroniseConsentCompletion?
    
    let bannerHeight: CGFloat = {
        kAPDAdSize320x50.height
    }()
    
    fileprivate lazy var bannerView: APDBannerView = {
        // Select banner ad size by current interface idiom
        let adSize = kAPDAdSize320x50
        
        let banner = APDBannerView(
            size:  adSize,
            rootViewController: UIApplication.shared.rootViewController ?? UIViewController()
        )
        // Set banner initial frame
        banner.frame = CGRect(
            x: 0,
            y: 0,
            width: adSize.width,
            height: adSize.height
        )
        
        banner.delegate = self
        
        return banner
    }()
    
    @UserDefault(key: .adsConsent) private var adsConsent: Bool? = nil

    // MARK: Published properties
    @Published var isAdInitialised     = false
    @Published var isBannerReady       = false
    
    private var isInitialized = false
    // MARK: Public methods
    func initialize() {
        guard !isInitialized else {return}
        isInitialized = true
        // Check user consent beforestak advertising
        // initialisation
        synchroniseConsent { [weak self] in
            self?.initializeAppodeaSDK()
        }
    }
    
    // MARK: Private methods
    private func initializeAppodeaSDK() {
        /// Test Mode
        #if DEBUG
        Appodeal.setTestingEnabled(true)
        Appodeal.setLogLevel(.error)
        #endif
        
        Appodeal.setAutocache(false, types: [.banner])
        let consent = adsConsent ?? (STKConsentManager.shared().consentStatus != .nonPersonalized)
        Appodeal.initialize(
            withApiKey: Config.current.appodealKey,
            types: [.banner],
            hasConsent: consent
        )
        
        // Trigger banner cache
        // It can be done after any moment after Appodeal initialisation
        bannerView.loadAd()
        
        self.isAdInitialised = true
    }
        
    private func synchroniseConsent(completion: SynchroniseConsentCompletion?) {
        STKConsentManager.shared().synchronize(withAppKey: Config.current.appodealKey) { error in
            error.map { print("Error while synchronising consent manager: \($0)") }
            guard STKConsentManager.shared().shouldShowConsentDialog == .true else {
                completion?()
                return
            }
            
            guard self.adsConsent == nil else {
                completion?()
                return
            }
            
            STKConsentManager.shared().loadConsentDialog { [weak self] error in
                error.map { print("Error while loading consent dialog: \($0)") }
                guard let controller = UIApplication.shared.rootViewController,
                    STKConsentManager.shared().isConsentDialogReady
                    else {
                        completion?()
                        return
                }
                
                self?.synchroniseConsentCompletion = completion
                STKConsentManager.shared().showConsentDialog(
                    fromRootViewController: controller,
                    delegate: self
                )
            }
        }
    }
}

// MARK: Protocols implementations
extension AdvertisingProvider: APDBannerViewDelegate {
    func bannerViewDidLoadAd(_ bannerView: APDBannerView,
                             isPrecache precache: Bool) {
        isBannerReady = true
    }
    
    func bannerView(_ bannerView: APDBannerView,
                    didFailToLoadAdWithError error: Error) {
        isBannerReady = false
    }
}


extension AdvertisingProvider: STKConsentManagerDisplayDelegate {
    func consentManager(_ consentManager: STKConsentManager, didFailToPresent error: Error) {
        synchroniseConsentCompletion?()
    }
    
    func consentManagerDidDismissDialog(_ consentManager: STKConsentManager) {
        adsConsent = STKConsentManager.shared().consentStatus != .nonPersonalized
        synchroniseConsentCompletion?()
    }
    
    // No-op
    func consentManagerWillShowDialog(_ consentManager: STKConsentManager) {}
}

#endif

extension UIApplication {
    /// Root view conntroller for advertising
    /// We get top presented controller from active scene window
    var rootViewController: UIViewController? {
        let window = connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap {$0 as? UIWindowScene }
            .first?
            .windows
            .filter { $0.isKeyWindow }
            .first
        
        var controller = window?.rootViewController
        while controller?.presentedViewController != nil {
            controller = controller?.presentedViewController
        }
        
        return controller
    }
}
