//
//  NCWalletTransactionsPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.03.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import CloudData

class NCWalletTransactionsPageViewController: NCPageViewController {
	
	private var accountChangeObserver: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let label = NCNavigationItemTitleLabel(frame: CGRect(origin: .zero, size: .zero))
		label.set(title: NSLocalizedString("Wallet Transactions", comment: ""), subtitle: nil)
		navigationItem.titleView = label
		
		
		accountChangeObserver = NotificationCenter.default.addNotificationObserver(forName: .NCCurrentAccountChanged, object: nil, queue: nil) { [weak self] _ in
			self?.reload()
		}
		reload()
	}
	
	private var errorLabel: UILabel? {
		didSet {
			oldValue?.removeFromSuperview()
			if let label = errorLabel {
				view.addSubview(label)
				label.frame = view.bounds.insetBy(UIEdgeInsetsMake(topLayoutGuide.length, 0, bottomLayoutGuide.length, 0))
			}
		}
	}
	
	
	private func reload() {
		guard let account = NCAccount.current else {return}
		let dataManager = NCDataManager(account: account)
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
		
		progress.progress.perform {
			dataManager.corpWalletBalance().then(on: .main) { result -> Void in
				guard let balance = result.value?.reduce(0, { $0 + $1.balance }) else {return}
				
				let label = self.navigationItem.titleView as? NCNavigationItemTitleLabel
				label?.set(title: NSLocalizedString("Wallet Journal", comment: ""), subtitle: NCUnitFormatter.localizedString(from: balance, unit: .isk, style: .full))
			}
			}.then {
				return progress.progress.perform {
					dataManager.divisions().then { result in
						return result.value?.wallet?.filter {$0.division != nil}
					}
				}
			}.then(on: .main) { result in
				guard let result = result, !result.isEmpty else {throw NCDataManagerError.noResult}
				self.viewControllers = result.map { division in
					let controller = self.storyboard!.instantiateViewController(withIdentifier: "NCWalletTransactionsViewController") as! NCWalletTransactionsViewController
					controller.wallet = .corporation(division)
					return controller
				}
				self.errorLabel = nil
			}.catch(on: .main) { error in
				self.errorLabel = NCTableViewBackgroundLabel(text: error.localizedDescription)
			}.finally(on: .main) {
				progress.finish()
		}
	}
}

