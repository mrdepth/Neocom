//
//  NCMailPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CloudData

class NCMailContainerViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.rightBarButtonItem = childViewControllers.first?.editButtonItem
	}
	
	@IBAction func onCompose(_ sender: Any) {
		Router.Mail.NewMessage().perform(source: self, sender: sender)
	}
}


class NCMailPageViewController: NCPageViewController {
	
	private var accountChangeObserver: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.isToolbarHidden = false
		navigationItem.rightBarButtonItem = editButtonItem
		reload()
		
		accountChangeObserver = NotificationCenter.default.addNotificationObserver(forName: .NCCurrentAccountChanged, object: nil, queue: nil) { [weak self] _ in
			self?.reload()
		}

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
	
	@IBAction func onCompose(_ sender: Any) {
		Router.Mail.NewMessage().perform(source: self, sender: sender)
	}

	private var mailLabels: CachedValue<ESI.Mail.MailLabelsAndUnreadCounts>?
	private var error: Error?
	
	func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		guard let account = NCAccount.current else {return}
		let dataManager = NCDataManager(account: account)
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
		
		progress.progress.perform {
			dataManager.mailLabels().then(on:. main) { result in
				self.error = nil
				self.mailLabels = result
				var controllers: [UIViewController]? = result.value?.labels?.map { label -> NCMailViewController in
					let controller = self.storyboard!.instantiateViewController(withIdentifier: "NCMailViewController") as! NCMailViewController
					controller.label = label
					return controller
				}
				controllers?.append(self.storyboard!.instantiateViewController(withIdentifier: "NCMailDraftsViewController"))
				self.viewControllers = controllers
				self.errorLabel = nil
			}.catch(on: .main) { error in
				self.errorLabel = NCTableViewBackgroundLabel(text: error.localizedDescription)
			}.finally(on: .main) {
				progress.finish()
			}
		}
	}
	
	
	func saveUnreadCount() {
		guard var value = mailLabels?.value, let record = mailLabels?.cacheRecord(in: NCCache.sharedCache!.viewContext) else {return}
		guard let labels = viewControllers?.compactMap ({($0 as? NCMailViewController)?.label}) else {return}
		
		value.totalUnreadCount = labels.compactMap {$0.unreadCount}.reduce(0, +)
		value.labels = labels
		record.set(value)
		
		if record.managedObjectContext?.hasChanges == true {
			try? record.managedObjectContext?.save()
		}
	}
	
}
