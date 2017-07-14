//
//  NCTreeViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 07.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

protocol NCSearchableViewController: UISearchResultsUpdating {
	var searchController: UISearchController? {get set}
}

extension NCSearchableViewController {
	func setupSearchController(searchResultsController: UIViewController) {
		guard let controller = self as? UITableViewController else {return}
		searchController = UISearchController(searchResultsController: searchResultsController)
		searchController?.searchBar.searchBarStyle = UISearchBarStyle.default
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.barStyle = UIBarStyle.black
		searchController?.hidesNavigationBarDuringPresentation = false
		controller.tableView.backgroundView = UIView()
		controller.tableView.tableHeaderView = searchController?.searchBar
		controller.definesPresentationContext = true
		
	}
}

class NCTreeViewController: UITableViewController, TreeControllerDelegate {
	var treeController: TreeController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.backgroundColor = UIColor.background
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		treeController = TreeController()
		treeController?.delegate = self
		treeController?.tableView = tableView
		
		tableView.delegate = treeController
		tableView.dataSource = treeController
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let route = (node as? TreeNodeRoutable)?.route {
			route.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		if let route = (node as? TreeNodeRoutable)?.accessoryButtonRoute {
			route.perform(source: self, view: treeController.cell(for: node))
		}
	}
	
}
