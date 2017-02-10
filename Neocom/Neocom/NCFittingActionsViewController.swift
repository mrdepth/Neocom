//
//  NCFittingActionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 10.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingActionsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	var ship: NCFittingShip?
	
	private var observer: NSObjectProtocol?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//navigationController?.preferredContentSize = CGSize(width: view.bounds.size.width, height: 320)
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		reload()
		tableView.layoutIfNeeded()
		var size = tableView.contentSize
		size.height += tableView.contentInset.top
		size.height += tableView.contentInset.bottom
		navigationController?.preferredContentSize = size
		
		if let ship = ship, observer == nil {
			observer = NotificationCenter.default.addObserver(forName: .NCFittingEngineDidUpdate, object: ship.engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
		
	}
	
	//MARK: - Private
	
	private func reload() {
		
	}
}
