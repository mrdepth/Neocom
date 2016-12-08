//
//  NCDatabaseTypeInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCDatabaseTypeInfoViewController: UITableViewController {
	var type: NCDBInvType?
	var headerViewController: NCDatabaseTypeInfoHeaderViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let type = type {
			title = type.typeName
			let headerViewController = self.storyboard!.instantiateViewController(withIdentifier: "NCDatabaseTypeInfoHeaderViewControllerSmall") as! NCDatabaseTypeInfoHeaderViewController
			headerViewController.type = type
			
			var frame = CGRect.zero
			frame.size = headerViewController.view.systemLayoutSizeFitting(CGSize(width: view.bounds.size.width, height:0), withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
			headerViewController.view.frame = frame
			tableView.tableHeaderView = UIView(frame: frame)
			tableView.addSubview(headerViewController.view)
			addChildViewController(headerViewController)
			self.headerViewController = headerViewController
		}
		else {
			title = NSLocalizedString("Unknown", comment: "")
		}
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		if let headerViewController = headerViewController {
			DispatchQueue.main.async {
				var frame = CGRect.zero
				frame.size = headerViewController.view.systemLayoutSizeFitting(CGSize(width: size.width, height:0), withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
				headerViewController.view.frame = frame
				self.tableView.tableHeaderView?.frame = frame
				self.tableView.tableHeaderView = self.tableView.tableHeaderView
			}
		}
	}
}
