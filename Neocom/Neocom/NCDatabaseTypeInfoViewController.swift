//
//  NCDatabaseTypeInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCDatabaseTypeInfoViewController: UITableViewController, NCTreeControllerDelegate {
	var type: NCDBInvType?
	var headerViewController: NCDatabaseTypeInfoHeaderViewController?
	
	@IBOutlet var treeController: NCTreeController!
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.childrenKeyPath = "children"
		treeController.delegate = self
		
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
			
			NCDatabaseTypeInfo.typeInfo(type: type) { result in
				self.treeController.content = result
				self.treeController.reloadData()
			}
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
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCDatabaseMarketInfoViewController"?:
			let controller = segue.destination as! NCDatabaseMarketInfoViewController
			controller.type = type
		default:
			break
		}
	}
	
	// MARK: NCTreeControllerDelegate
	
	func treeController(_ treeController: NCTreeController, cellIdentifierForItem item: AnyObject) -> String {
		return (item as! NCTreeNode).cellIdentifier
	}
	
	func treeController(_ treeController: NCTreeController, configureCell cell: UITableViewCell, withItem item: AnyObject) {
		(item as! NCTreeNode).configure(cell: cell)
	}
	
	func treeController(_ treeController: NCTreeController, isItemExpandable item: AnyObject) -> Bool {
		return (item as! NCTreeNode).canExpand
	}
	
	func treeController(_ treeController: NCTreeController, didSelectCell cell: UITableViewCell, withItem item: AnyObject) {
		switch item {
		case let item as NCDatabaseTypeInfoRow where item.segue != nil:
			self.performSegue(withIdentifier: item.segue!, sender: cell)
		case is NCDatabaseTypeMarketRow:
			self.performSegue(withIdentifier: "NCDatabaseMarketInfoViewController", sender: cell)
		default:
			treeController.deselectItem(item, animated: true)
			break
		}
	}
}


