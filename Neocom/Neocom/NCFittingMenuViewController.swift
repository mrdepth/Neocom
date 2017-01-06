//
//  NCFittingMenuViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingMenuViewController: UITableViewController, NCTreeControllerDelegate {
	@IBOutlet var treeController: NCTreeController!

    override func viewDidLoad() {
        super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.childrenKeyPath = "children"
		treeController.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController.content == nil {
			var sections = [NCTreeNode]()
			sections.append(NCDefaultTreeRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "fitting"), title: NSLocalizedString("New Ship Fit", comment: ""), accessoryType: .disclosureIndicator, segue: ""))
			sections.append(NCDefaultTreeRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "station"), title: NSLocalizedString("New Structure Fit", comment: ""), accessoryType: .disclosureIndicator, segue: ""))
			sections.append(NCDefaultTreeRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "browser"), title: NSLocalizedString("Import/Export", comment: ""), accessoryType: .disclosureIndicator, segue: ""))
			sections.append(NCDefaultTreeRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "eveOnlineLogin"), title: NSLocalizedString("Browse Ingame Fits", comment: ""), accessoryType: .disclosureIndicator, segue: ""))
			treeController.content = sections
			treeController.reloadData()
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

}
