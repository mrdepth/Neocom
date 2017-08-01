//
//  NCKillmailsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI

class NCKillmailsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCKillmailTableViewCell.default
		                    ])
		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateBackground()
	}
	
	var error: Error? {
		didSet {
			updateBackground()
		}
	}
	
	func updateBackground() {
		if (treeController?.content?.children.count ?? 0) > 0 {
			tableView.backgroundView = nil
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: error == nil ? NSLocalizedString("No Results", comment: "") : error!.localizedDescription)
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeControllerDidUpdateContent(_ treeController: TreeController) {
		updateBackground()
	}
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		(parent as? NCKillmailsPageViewController)?.fetchIfNeeded()
	}
	
	//MARK: - Private
	
	@objc private func refresh() {
		guard let parent = parent as? NCKillmailsPageViewController, !parent.isFetching else {
			refreshControl?.endRefreshing()
			return
		}
		parent.reload(cachePolicy: .reloadIgnoringLocalCacheData)
	}
	
}
