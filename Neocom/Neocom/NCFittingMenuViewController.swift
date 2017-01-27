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
	var sections: [[NCTreeNode]]?

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
		if sections == nil {
			var ships = [NCTreeNode]()
			ships.append(NCDefaultTreeRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "fitting"), title: NSLocalizedString("New Ship Fit", comment: ""), accessoryType: .disclosureIndicator, segue: "NCTypePickerViewController", object: NCDBDgmppItemCategoryID.ship))
			ships.append(NCDefaultTreeRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "browser"), title: NSLocalizedString("Import/Export", comment: ""), accessoryType: .disclosureIndicator, segue: ""))
			ships.append(NCDefaultTreeRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "eveOnlineLogin"), title: NSLocalizedString("Browse Ingame Fits", comment: ""), accessoryType: .disclosureIndicator, segue: ""))
			
			var structures = [NCTreeNode]()
			structures.append(NCDefaultTreeRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "station"), title: NSLocalizedString("New Structure Fit", comment: ""), accessoryType: .disclosureIndicator, segue: "NCTypePickerViewController", object: NCDBDgmppItemCategoryID.structure))
			structures.append(NCDefaultTreeRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "browser"), title: NSLocalizedString("Import/Export", comment: ""), accessoryType: .disclosureIndicator, segue: ""))
			
			sections = [ships, structures]
			
			treeController.content = sections?[0]
			treeController.reloadData()
		}
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCTypePickerViewController"?:
			guard let controller = segue.destination as? NCTypePickerViewController else {return}
			guard let categoryID = (sender as? NCTableViewCell)?.object as? NCDBDgmppItemCategoryID else {return}
			controller.category = NCDBDgmppItemCategory.category(categoryID: categoryID)
			controller.completionHandler = { [weak self] (type) in
				print ("\(type)")
				self?.dismiss(animated: true)
			}
		case "NCShipFittingViewController"?:
			guard let controller = segue.destination as? NCShipFittingViewController else {return}
			guard let (engine, fleet) = sender as? (NCFittingEngine, NCFleet) else {return}
			controller.engine = engine
			controller.fleet = fleet
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

	func treeController(_ treeController: NCTreeController, didSelectCell cell: UITableViewCell, withItem item: AnyObject) -> Void {
		guard let row = item as? NCDefaultTreeRow else {return}
		if let segue = row.segue {
			guard let controller = storyboard?.instantiateViewController(withIdentifier: "NCTypePickerViewController") as? NCTypePickerViewController else {return}
			controller.category = NCDBDgmppItemCategory.category(categoryID: row.object as! NCDBDgmppItemCategoryID)
			controller.completionHandler = { [weak self] (type) in
				let engine = NCFittingEngine()
				let typeID = Int(type.typeID)
				engine.perform {
					let fleet = NCFleet(typeID: typeID, engine: engine)
					DispatchQueue.main.async {
						self?.dismiss(animated: true)
						self?.performSegue(withIdentifier: "NCShipFittingViewController", sender: (engine, fleet))
					}
				}
			}
			self.present(controller, animated: true, completion: nil)
			//self.performSegue(withIdentifier: segue, sender: cell)
		}
	}
	
	func treeController(_ treeController: NCTreeController, canEditChild child: Int, ofItem item: AnyObject?) -> Bool {
		return true
	}
}
