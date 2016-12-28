//
//  NCDatabaseTypeInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCDatabaseTypeInfoViewController: UITableViewController, NCTreeControllerDelegate, UIViewControllerPreviewingDelegate {
	var type: NCDBInvType?
	var headerViewController: NCDatabaseTypeInfoHeaderViewController?
	
	@IBOutlet var treeController: NCTreeController!
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.childrenKeyPath = "children"
		treeController.delegate = self
		registerForPreviewing(with: self, sourceView: tableView)
		
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
			NCDataManager().image(typeID: Int(type.typeID), dimension: 512) { result in
				switch result {
				case let .success(value: value, cacheRecordID: _):
					let to = self.storyboard!.instantiateViewController(withIdentifier: "NCDatabaseTypeInfoHeaderViewControllerLarge") as! NCDatabaseTypeInfoHeaderViewController
					to.type = type
					to.image = value
					var frame = CGRect.zero
					frame.size = to.view.systemLayoutSizeFitting(CGSize(width: self.view.bounds.size.width, height:0), withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
					to.view.frame = frame
					to.view.layoutIfNeeded()

					let from = self.headerViewController!
					
					from.willMove(toParentViewController: nil)
					self.addChildViewController(to)
					to.view.alpha = 0.0;
					self.transition(from: from, to: to, duration: 0.25, options: [], animations: {
						from.view.alpha = 0.0;
						to.view.alpha = 1.0;
						self.tableView?.tableHeaderView?.frame = frame;
						self.tableView?.tableHeaderView = self.tableView?.tableHeaderView;
					}, completion: { (fihisned) in
						from.removeFromParentViewController()
						to.didMove(toParentViewController: self)
					})

					
				default:
					break
				}
			}
			
		}
		else {
			title = NSLocalizedString("Unknown", comment: "")
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(didChangeMarketRegion(_:)), name: .NCMarketRegionChanged, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
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
		case "NCDatabaseTypeInfoViewController"?:
			let controller = segue.destination as? NCDatabaseTypeInfoViewController
			let object = (sender as! NCDefaultTableViewCell).object as! NSManagedObjectID
			controller?.type = (try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: object)) as? NCDBInvType
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
		if let controller = targetController(forItem: item) {
			self.show(controller, sender: cell)
		}
		else {
			treeController.deselectItem(item, animated: true)
		}
	}
	
	// MARK: UIViewControllerPreviewingDelegate
	
	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard let indexPath = tableView.indexPathForRow(at: location) else {return nil}
		guard let item = treeController.item(forIndexPath: indexPath) else {return nil}
		return targetController(forItem: item)
	}
	
	func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		show(viewControllerToCommit, sender: self)
	}
	
	// MARK: Private
	
	@objc private func didChangeMarketRegion(_ note: Notification) {
		if let type = type {
			NCDatabaseTypeInfo.typeInfo(type: type) { result in
				self.treeController.content = result
				self.treeController.reloadData()
			}
		}
	}
	
	func targetController(forItem item: AnyObject) -> UIViewController? {
		let segue = (item as? NCDatabaseTypeInfoRow)?.segue
		switch (item, segue) {
		case (is NCDatabaseTypeMarketRow, _), (_, "NCDatabaseMarketInfoViewController"?):
			let controller = self.storyboard?.instantiateViewController(withIdentifier: "NCDatabaseMarketInfoViewController") as! NCDatabaseMarketInfoViewController
			controller.type = type
			return controller
		case (is NCDatabaseTypeSkillRow, _), (_, "NCDatabaseTypeInfoViewController"?):
			let controller = self.storyboard?.instantiateViewController(withIdentifier: "NCDatabaseTypeInfoViewController") as! NCDatabaseTypeInfoViewController
			let object = item.object as! NSManagedObjectID
			controller.type = try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: object) as! NCDBInvType
			return controller
		case (_, "NCDatabaseTypesViewController"?):
			let controller = self.storyboard?.instantiateViewController(withIdentifier: "NCDatabaseTypesViewController") as! NCDatabaseTypesViewController
			let object = item.object as! NSManagedObjectID
			let group = try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: object) as! NCDBInvGroup
				controller.predicate = NSPredicate(format: "group = %@", group!)
			controller.title = group!.groupName
			return controller
		case (_, "NCDatabaseCertificateMasteryViewController"?):
			let controller = self.storyboard?.instantiateViewController(withIdentifier: "NCDatabaseCertificateMasteryViewController") as! NCDatabaseCertificateMasteryViewController
			let object = item.object as! NSManagedObjectID
			let level = try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: object) as! NCDBCertMasteryLevel
			controller.type = type
			controller.level = level
			return controller
		default:
			return nil
		}
	}
	
}


