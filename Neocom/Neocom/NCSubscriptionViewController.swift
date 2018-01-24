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
							Prototype.NCHeaderTableViewCell.empty,
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
			var rows: [TreeNode] = []
			
			let title = NSLocalizedString("Ad Free Subscription", comment: "")
			let subtitle = NSLocalizedString("Tired of seeing those pesky ads? Why not upgrade to an Ad Free Subscription!", comment: "")
			let features = NSLocalizedString("- Remove ads from every screen\n- Remove ads across all devices with the same Apple ID", comment: "")
			
			rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
				DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, nodeIdentifier: "Introduction", title: title, subtitle: subtitle)
				]))
//			rows.append()
			rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
				DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, nodeIdentifier: "Features", title: NSLocalizedString("Ad Free Subscriptions will", comment: ""), subtitle: features)
				]))
//			rows.append()

			let formatter = NumberFormatter()
			formatter.numberStyle = .currency

			if case let .success(receipt) = result,
				let purchase = receipt.inAppPurchases?.filter ({$0.isSubscription && !$0.isExpired}).max(by: {$0.expiresDate! < $1.expiresDate!}) {
				
				if let inApp = InAppProductID(rawValue: purchase.productID) {
					let title: String?
					if let product = self.products?.first(where: {$0.productIdentifier == purchase.productID}) {
						formatter.locale = product.priceLocale
						title = NSLocalizedString("Subscription ACTIVE", comment: "") + ": \(formatter.string(from: product.price) ?? "") / \(inApp.period)"
					}
					else {
						title = NSLocalizedString("Subscription ACTIVE", comment: "")
					}
					let formatter = DateFormatter()
					formatter.dateStyle = .medium
					formatter.timeStyle = .none
					let subtitle = NSLocalizedString("Renews", comment: "") + " " + formatter.string(from: purchase.expiresDate!)
					rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
						DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, nodeIdentifier: "Subscription", title: title, subtitle: subtitle)
						]))
				}
			}
			else {
				
				if let plans = self.products?.flatMap ({ i -> TreeNode? in
					guard let inApp = InAppProductID(rawValue: i.productIdentifier) else {return nil}
					formatter.locale = i.priceLocale
					let title = NSLocalizedString("Subscribe for ", comment: "").uppercased() + "\(formatter.string(from: i.price) ?? "")" * [NSAttributedStringKey.foregroundColor: UIColor.white] + " / \(inApp.period.uppercased())"
					return NCActionRow(attributedTitle: title, object: i)
				}), !plans.isEmpty {
					rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: plans))
				}
				
				rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
					NCActionRow(title: NSLocalizedString("Restore Purchase", comment: "").uppercased())
					]))
				//					rows.append()
				
			}
			
			let footer = NSLocalizedString("Subscription will be automatically renewed within 1 day before the current subscription ends. Auto-renew option can be turned off in iTunes Account Settings.", comment: "")
			rows.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
				DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, nodeIdentifier: "Footer", subtitle: footer)
				]))

			self.treeController?.content = RootNode(rows)
			completionHandler()
		}
	}
	
	private var progressHandler: NCProgressHandler?
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
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
	}
	
	private var products: [SKProduct]?
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
		let controller = UIAlertController(title: NSLocalizedString("Restore Purchase", comment: ""), message: NSLocalizedString("Done", comment: ""), preferredStyle: .alert)
		controller.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
		present(controller, animated: true, completion: nil)
		updateContent { }
	}
}
