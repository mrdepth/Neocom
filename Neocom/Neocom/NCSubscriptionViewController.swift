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

class NCSubscriptionViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.noImage,
							Prototype.NCDefaultTableViewCell.attributeNoImage,
							Prototype.NCHeaderTableViewCell.empty,
							Prototype.NCSubscriptionTableViewCell.default,
							Prototype.NCActionTableViewCell.default])
		
		let request = SKProductsRequest(productIdentifiers: Set([InAppProductID.removeAdsMonth.rawValue]))
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
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		/*
		return;*/
		
		Receipt.fetchValidReceipt { result in
			defer {completionHandler()}
			guard let products = self.products ?? (UIApplication.shared.delegate as? NCAppDelegate)?.products, !products.isEmpty else {return}

			var rows: [TreeNode] = []
			
			let title = NSLocalizedString("Ad Free Subscription", comment: "")
			let subtitle = NSLocalizedString("Tired of seeing those pesky ads? Why not upgrade to an Ad Free Subscription!", comment: "")
			let features = NSLocalizedString("- Remove ads from every screen\n- Remove ads across all devices with the same Apple ID", comment: "")
			
			rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
				DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, nodeIdentifier: "Introduction", title: title, subtitle: [subtitle, features].joined(separator: "\n"))
				]))
//			rows.append()
//			rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
//				DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, nodeIdentifier: "Features", title: NSLocalizedString("Ad Free Subscriptions will", comment: ""), subtitle: features)
//				]))
//			rows.append()

			let formatter = NumberFormatter()
			formatter.numberStyle = .currency


			if case let .success(receipt) = result,
				let purchase = receipt.inAppPurchases?.filter ({$0.inAppType == .autoRenewableSubscription && !$0.isExpired}).max(by: {$0.expiresDate! < $1.expiresDate!}) {
				
				if let product = products.first(where: {$0.productIdentifier == purchase.productID}) {
					let route = Router.Custom { (_, _) in
						UIApplication.shared.openURL(NCManageSubscriptionsURL)
					}
					
					rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
						NCSubscriptionStatusRow(product: product, purchase: purchase),
						NCActionRow(title: NSLocalizedString("Cancel Subscription", comment: "").uppercased(), route: route)
						]))
				}
			}
			else {
				let plans = products.flatMap ({ i -> TreeNode? in
					let route = Router.Custom { [weak self] (_, sender) in
						self?.purchase(product: i, sender: sender)
					}
					return NCSubscriptionRow(product: i, route: route)
				})
				
				if !plans.isEmpty {
					rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: plans))
				}
				
				let route = Router.Custom { [weak self] (_, sender) in
					self?.restorePurchases(sender: sender)
				}

				rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
					DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Restore Purchases", comment: "").uppercased(), subtitle: NSLocalizedString("Already subscribed? Try to restore your purchases.", comment: ""), route: route)
					]))
				//					rows.append()
				
			}
			
//			let footer = NSLocalizedString("Subscription will be automatically renewed within 1 day before the current subscription ends. Auto-renew option can be turned off in iTunes Account Settings.", comment: "")
			formatter.locale = products[0].priceLocale
			let footer = String(format: NSLocalizedString("Payment will be charged to your credit card through your iTunes Account at confirmation purchase. 1 Month Subscription will be charged as %@ per month. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Auto-renew option can be turned off in iTunes Account Settings.", comment: ""), formatter.string(from: products[0].price) ?? "")
			
//			let footer = NSLocalizedString("Subscription will be charged to your credit card through your iTunes Account. Subscription will be automatically renewed within 1 day before the current subscription ends. Auto-renew option can be turned off in iTunes Account Settings.", comment: "")
			rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
				DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, nodeIdentifier: "Footer", subtitle: footer),

				]))

			rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
				NCActionRow(title: NSLocalizedString("Privacy Policy", comment: "").uppercased(), route: Router.Custom({ (_, _) in
					UIApplication.shared.openURL(NCPrivacy)
				})),
				NCActionRow(title: NSLocalizedString("Terms of Use", comment: "").uppercased(), route: Router.Custom({ (_, _) in
					UIApplication.shared.openURL(NCTerms)
				})),
				
				]))
			
			self.treeController?.content = RootNode(rows)
		}
	}
	
	/*override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCActionRow else {return}
		if let product = row.object as? SKProduct {
			if let cell = treeController.cell(for: node) {
				tableView.isUserInteractionEnabled = false
				progressHandler = NCProgressHandler(view: cell, totalUnitCount: 1, activityIndicatorStyle: .white)
				SKPaymentQueue.default().add(SKPayment(product: product))
			}
		}
		else {
			if let cell = treeController.cell(for: node) {
				tableView.isUserInteractionEnabled = false
				progressHandler = NCProgressHandler(view: cell, totalUnitCount: 1, activityIndicatorStyle: .white)
				SKPaymentQueue.default().restoreCompletedTransactions()
			}

		}
	}*/
	
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
		products = response.products
		updateContent {}
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
			updateContent { }
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
		let controller = UIAlertController(title: NSLocalizedString("Purchases Restored", comment: ""), message: NSLocalizedString("Your previous purchases are being restored. Thank you!", comment: ""), preferredStyle: .alert)
		controller.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
		present(controller, animated: true, completion: nil)
//		updateContent { }
	}
}
