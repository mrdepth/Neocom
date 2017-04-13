//
//  NCContactsSearchResultViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

protocol NCContactsSearchResultsViewControllerDelegate: NSObjectProtocol {
	func contactsSearchResultsViewController(_ controller: NCContactsSearchResultsViewController, didSelectContact: Int64)
}

class NCContactsSearchResultsViewController: UITableViewController {
	
	var contacts: [Int: String] = [:]
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
}
