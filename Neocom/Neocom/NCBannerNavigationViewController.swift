//
//  NCBannerNavigationViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import Appodeal
import ASReceipt
import StoreKit

class NCBannerNavigationViewController: NCNavigationController {
	
	lazy var bannerView: AppodealBannerView? = {
		let bannerView = AppodealBannerView(size: kAppodealUnitSize_320x50, rootViewController: self)
		bannerView?.translatesAutoresizingMaskIntoConstraints = false
		bannerView?.widthAnchor.constraint(equalToConstant: kAppodealUnitSize_320x50.width).isActive = true
		bannerView?.heightAnchor.constraint(equalToConstant: kAppodealUnitSize_320x50.height).isActive = true
		bannerView?.setDelegate(self)
		return bannerView
	}()
	
	lazy var bannerContainerView: UIView? = {
		guard let bannerView = self.bannerView else {return nil}
		
		let bannerContainerView = NCBackgroundView(frame: .zero)
		bannerContainerView.translatesAutoresizingMaskIntoConstraints = false
		bannerContainerView.addSubview(bannerView)
		
		bannerView.centerXAnchor.constraint(equalTo: bannerContainerView.centerXAnchor).isActive = true
		bannerView.topAnchor.constraint(equalTo: bannerContainerView.topAnchor, constant: 4).isActive = true
		return bannerContainerView
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		#if TARGET_OS_SIMULATOR1
		#else
		Receipt.fetchValidReceipt { [weak self] (result) in
			guard let strongSelf = self else {return}
			if case let .success(receipt) = result, receipt.inAppPurchases?.contains(where: {$0.inAppType == .autoRenewableSubscription && !$0.isExpired}) == true {
				return
			}
			else {
				let firstLaunchDate = UserDefaults.standard.object(forKey: UserDefaults.Key.NCFirstLaunchDate) as? Date ?? Date()
				if firstLaunchDate.timeIntervalSinceNow < -TimeInterval.NCBannerStartTime {
					strongSelf.bannerView?.loadAd()
					SKPaymentQueue.default().add(strongSelf)
				}
			}
		}
		#endif
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if let bannerContainerView = self.bannerContainerView, bannerContainerView.superview != nil {
//			if #available(iOS 11.0, *) {
//			}
//			else {
//				view.subviews.first?.frame = view.bounds.insetBy(UIEdgeInsets(top: 0, left: 0, bottom: bannerContainerView.bounds.height, right: 0))
//			}
			view.subviews.first?.frame = view.bounds.insetBy(UIEdgeInsets(top: 0, left: 0, bottom: bannerContainerView.bounds.height, right: 0))

		}
		else {
			view.subviews.first?.frame = view.bounds
		}
	}
	
	//MARK: - Private
	
	private func showBanner() {
		guard let bannerContainerView = bannerContainerView,
			let bannerView = bannerView,
			bannerContainerView.superview == nil else {return}
		
		view.addSubview(bannerContainerView)
		
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": bannerContainerView]))
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:[view]-0-|", options: [], metrics: nil, views: ["view": bannerContainerView]))
		
//		if #available(iOS 11.0, *) {
////			bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: kAppodealUnitSize_320x50.height).isActive = true
//
////			additionalSafeAreaInsets.bottom = kAppodealUnitSize_320x50.height
//
//		} else {
//			bannerView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
//		}
		bannerView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true

	}
	
	private func hideBanner() {
		guard let bannerContainerView = bannerContainerView,
			bannerContainerView.superview != nil else {return}

		if #available(iOS 11.0, *) {
			additionalSafeAreaInsets.bottom = 0
		}
		bannerContainerView.removeFromSuperview()
	}
	
	private func removeBanner() {
		bannerContainerView?.removeFromSuperview()
		bannerContainerView = nil
		bannerView = nil
		SKPaymentQueue.default().remove(self)
	}
}

extension NCBannerNavigationViewController: AppodealBannerViewDelegate {
	
	func bannerViewDidLoadAd(_ bannerView: APDBannerView!) {
		showBanner()
	}
	
	func bannerView(_ bannerView: APDBannerView!, didFailToLoadAdWithError error: Error!) {
		hideBanner()
	}
	
}

extension NCBannerNavigationViewController: SKPaymentTransactionObserver {
	
	func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		guard bannerContainerView != nil else {return}
		
		if transactions.contains(where: {$0.transactionState == .purchased || $0.transactionState == .restored}) {
			Receipt.fetchValidReceipt { [weak self] (result) in
				if case let .success(receipt) = result, receipt.inAppPurchases?.contains(where: {$0.inAppType == .autoRenewableSubscription && !$0.isExpired}) == true {
					self?.removeBanner()
				}
			}
		}
	}

}
