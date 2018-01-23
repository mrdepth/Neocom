//
//  NCBannerNavigationViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import Appodeal

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
		bannerView?.loadAd()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if let bannerContainerView = self.bannerContainerView, bannerContainerView.superview != nil {
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
		if #available(iOS 11.0, *) {
			view.insetsLayoutMarginsFromSafeArea = false
		}
		
		view.addSubview(bannerContainerView)
		
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": bannerContainerView]))
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:[view]-0-|", options: [], metrics: nil, views: ["view": bannerContainerView]))
		
		bannerView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
		
	}
	
	private func hideBanner() {
		guard let bannerContainerView = bannerContainerView,
			bannerContainerView.superview != nil else {return}

		if #available(iOS 11.0, *) {
			view.insetsLayoutMarginsFromSafeArea = true
		}
		bannerContainerView.removeFromSuperview()
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
