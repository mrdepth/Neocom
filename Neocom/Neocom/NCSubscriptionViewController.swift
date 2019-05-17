//
//  NCSubscriptionViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.01.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import ASReceipt
import StoreKit
import EVEAPI
import Futures

class NCSubscriptionViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.noImage,
							Prototype.NCDefaultTableViewCell.attributeNoImage,
							Prototype.NCHeaderTableViewCell.empty,
							Prototype.NCHeaderTableViewCell.static,
							Prototype.NCSubscriptionTableViewCell.default,
							Prototype.NCActionTableViewCell.default,
							Prototype.NCFooterTableViewCell.default])
		
		let request = SKProductsRequest(productIdentifiers: Set(InAppProductID.all.map{$0.rawValue}))
		request.delegate = self
		request.start()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		SKPaymentQueue.default().add(self)

	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		SKPaymentQueue.default().remove(self)
	}
	
	override func content() -> Future<TreeNode?> {
		let promise = Promise<TreeNode?>()
		
		Receipt.fetchValidReceipt(refreshIfNeeded: false) { result in
			guard let products = self.products ?? (UIApplication.shared.delegate as? NCAppDelegate)?.products, !products.isEmpty else {
				try! promise.fulfill(nil)
				return
			}

			var rows: [TreeNode] = []
			
			let title = NSLocalizedString("Ad Free Subscription", comment: "")
			let subtitle = NSLocalizedString("Tired of seeing those pesky ads? Why not upgrade to an Ad Free Subscription!", comment: "")
			let features = NSLocalizedString("- Remove ads from every screen\n- Remove ads across all devices with the same Apple ID", comment: "")
			
			rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, nodeIdentifier: "IntroductionSection", isExpandable: false, children: [
				DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, nodeIdentifier: "Introduction", title: title, subtitle: [subtitle, features].joined(separator: "\n"))
				]))


			if case let .success(receipt) = result,
				let purchase = receipt.inAppPurchases?.filter ({$0.inAppType == .autoRenewableSubscription && !$0.isExpired}).max(by: {$0.expiresDate! < $1.expiresDate!}) {
				
				if let product = products.first(where: {$0.productIdentifier == purchase.productID}), let inApp = InAppProductID(rawValue: product.productIdentifier) {
					let route = Router.Custom { (_, _) in
						UIApplication.shared.openURL(NCManageSubscriptionsURL)
					}
					
					rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.static, title: NSLocalizedString("Active Subscription", comment: "").uppercased(), isExpandable: false, children: [
						NCSubscriptionStatusRow(product: product, inApp: inApp, purchase: purchase),
						]))
					
					let plans = products.filter {$0 != product}.compactMap ({ i -> TreeNode? in
						guard let inApp = InAppProductID(rawValue: i.productIdentifier) else {return nil}
						let route = Router.Custom { [weak self] (_, sender) in
							self?.purchase(product: i, sender: sender)
						}
						return NCSubscriptionRow(product: i, inApp: inApp, route: route)
					})
					let dateFormatter = DateFormatter()
					dateFormatter.dateStyle = .medium
					dateFormatter.timeStyle = .none
					let footer = String(format: NSLocalizedString("Your new subscription plan will begin and you'll be charged when your current subscription expires on %@", comment: ""), dateFormatter.string(from: purchase.expiresDate!))
					rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.static, title: NSLocalizedString("Change Subscription Plan", comment: "").uppercased(), isExpandable: false, children: plans))
					rows.append(NCFooterRow(nodeIdentifier: "PlansFooter", title: footer))

					rows.append(//DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
						NCActionRow(title: NSLocalizedString("Manage Subscriptions", comment: "").uppercased(), route: route)
						//])
					)

				}
			}
			else {
				let plans = products.compactMap ({ i -> TreeNode? in
					guard let inApp = InAppProductID(rawValue: i.productIdentifier) else {return nil}
					let route = Router.Custom { [weak self] (_, sender) in
						self?.purchase(product: i, sender: sender)
					}
					return NCSubscriptionRow(product: i, inApp: inApp, route: route)
				})
				
				if !plans.isEmpty {
					rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.static, title: NSLocalizedString("SUBSCRIPTION PLANS", comment: "").uppercased(), isExpandable: false, children: plans))
				}
				
				let route = Router.Custom { [weak self] (_, sender) in
					self?.restorePurchases(sender: sender)
				}

				rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
					DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Restore Purchases", comment: "").uppercased(), subtitle: NSLocalizedString("Already subscribed? Try to restore your purchases.", comment: ""), route: route)
					]))
				
			}
			
			let priceFormatter = NumberFormatter()
			priceFormatter.numberStyle = .currency
			priceFormatter.locale = products[0].priceLocale
//			let footer = String(format: NSLocalizedString("Payment will be charged to your credit card through your iTunes Account at confirmation purchase. 1 Month Subscription will be charged as %@ per month. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Auto-renew option can be turned off in iTunes Account Settings.", comment: ""), priceFormatter.string(from: products[0].price) ?? "")
			
			let footer = NSLocalizedString("Payment will be charged to iTunes Account at confirmation of purchase.\nSubscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.\nAccount will be charged for renewal within 24-hours prior to the end of the current period.\nAuto-renew option can be turned off in iTunes Account Settings.", comment: "")

			rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
				NCFooterRow(nodeIdentifier: "Footer", title: footer),
				
				]))

			
			rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
				NCActionRow(title: NSLocalizedString("Privacy Policy", comment: "").uppercased(), route: Router.Custom({ (_, _) in
					UIApplication.shared.openURL(NCPrivacy)
				})),
				NCActionRow(title: NSLocalizedString("Terms of Use", comment: "").uppercased(), route: Router.Custom({ (_, _) in
					UIApplication.shared.openURL(NCTerms)
				})),
				
				]))
			try! promise.fulfill(RootNode(rows))
		}
		
		return promise.future
	}
	
	private var products: [SKProduct]?
	
	private var progressHandler: NCProgressHandler?

	private func purchase(product: SKProduct, sender: Any?) {
		guard let cell = sender as? UITableViewCell else {return}
		tableView.isUserInteractionEnabled = false
		progressHandler = NCProgressHandler(view: cell, totalUnitCount: 1, activityIndicatorStyle: .white)
		SKPaymentQueue.default().add(SKPayment(product: product))

	}
	
	private func restorePurchases(sender: Any?) {
		guard let cell = sender as? UITableViewCell else {return}
		tableView.isUserInteractionEnabled = false
		progressHandler = NCProgressHandler(view: cell, totalUnitCount: 1, activityIndicatorStyle: .white)
		SKPaymentQueue.default().restoreCompletedTransactions()
	}
}

extension NCSubscriptionViewController: SKProductsRequestDelegate {
	public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
		products = response.products.sorted {$0.price.doubleValue < $1.price.doubleValue}
		updateContent()
	}
}

extension NCSubscriptionViewController: SKPaymentTransactionObserver {
	func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		if let error = transactions.first(where: {$0.transactionState == .failed})?.error {
			if (error as? SKError)?.code != SKError.paymentCancelled {
				present(UIAlertController(error: error), animated: true, completion: nil)
			}
		}
		if transactions.contains (where: {$0.transactionState == .purchased || $0.transactionState == .failed || $0.transactionState == .restored}) {
			progressHandler?.finish()
			progressHandler = nil
			tableView.isUserInteractionEnabled = true
			updateContent()
		}
	}
	
	func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
		if (error as? SKError)?.code != SKError.paymentCancelled {
			present(UIAlertController(error: error), animated: true, completion: nil)
		}
		progressHandler?.finish()
		progressHandler = nil
		tableView.isUserInteractionEnabled = true
	}
	
	func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
		progressHandler?.finish()
		progressHandler = nil
		tableView.isUserInteractionEnabled = true
		let (title, message) = (try? Receipt().inAppPurchases?.isEmpty) == false
			? (NSLocalizedString("Purchases Restored", comment: ""), NSLocalizedString("Your previous purchases are being restored. Thank you!", comment: ""))
			: (NSLocalizedString("No Purchases to Restore", comment: ""), NSLocalizedString("No purchases have been made under this Apple ID. Use the Apple ID that is linked to the purchase made.", comment: ""))
		let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
		controller.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
		present(controller, animated: true, completion: nil)
//		updateContent { }
	}
}
