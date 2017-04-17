//
//  NCMailViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
//import EVEAPI


class NCMailViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		guard let account = NCAccount.current else {return}
		
		treeController.content = NCMailFetchedResultsNode(account: account)
		
		NCDataManager(account: account).fetchMail { [weak self] result in
			switch result {
			case .success:
				break
			case let .failure(error):
				break
			}
		}
	}
}
