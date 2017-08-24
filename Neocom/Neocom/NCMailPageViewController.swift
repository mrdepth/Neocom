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

class NCMailPageViewController: NCPageViewController {
	
	private var accountChangeObserver: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
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
	
	private var mailLabels: NCCachedResult<ESI.Mail.MailLabelsAndUnreadCounts>?
	
	func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		guard let account = NCAccount.current else {return}
		let dataManager = NCDataManager(account: account)
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
		
		progress.progress.perform {
			dataManager.mailLabels { result in
				self.mailLabels = result
				switch result {
				case let .success(value, _):
					var controllers: [UIViewController]? = value.labels?.map { label -> NCMailViewController in
						let controller = self.storyboard!.instantiateViewController(withIdentifier: "NCMailViewController") as! NCMailViewController
						controller.label = label
						return controller
					}
					controllers?.append(self.storyboard!.instantiateViewController(withIdentifier: "NCMailDraftsViewController"))
					self.viewControllers = controllers
					self.errorLabel = nil
				case let .failure(error):
					self.errorLabel = NCTableViewBackgroundLabel(text: error.localizedDescription)
				}
				progress.finish()
			}
		}
	}
	
	@IBAction func onCompose(_ sender: Any) {
		Router.Mail.NewMessage().perform(source: self, sender: sender)
	}
	
	func saveUnreadCount() {
		switch mailLabels {
		case let .success(value, record)?:
			guard let record = record else {return}
			guard let labels = viewControllers?.flatMap ({($0 as? NCMailViewController)?.label}) else {return}
			let value = value.copy() as? ESI.Mail.MailLabelsAndUnreadCounts
			
			value?.totalUnreadCount = labels.flatMap {$0.unreadCount}.reduce(0, +)
			value?.labels = labels
			record.data?.data = value

			if record.managedObjectContext?.hasChanges == true {
				try? record.managedObjectContext?.save()
			}
		default:
			break
		}
	}
	
}
