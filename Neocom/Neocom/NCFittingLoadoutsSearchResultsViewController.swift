//
//  NCFittingLoadoutsSearchResultsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class NCFittingLoadoutsSearchResultsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.default,
							Prototype.NCHeaderTableViewCell.default])

	}
	
}
