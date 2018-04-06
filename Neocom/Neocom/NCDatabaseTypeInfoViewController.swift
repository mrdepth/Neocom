//
//  NCDatabaseTypeInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI

class NCDatabaseTypeInfoViewController: NCTreeViewController, UIViewControllerPreviewingDelegate {
	var type: NCDBInvType?
	var attributeValues: [Int: Double]?
	
	var headerViewController: NCDatabaseTypeInfoHeaderViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCActionHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.attribute,
		                    Prototype.NCDefaultTableViewCell.attributeNoImage,
		                    Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCDefaultTableViewCell.noImage,
		                    Prototype.NCDamageTypeTableViewCell.compact])
		
		registerForPreviewing(with: self, sourceView: tableView)
		
		if let type = type {
			title = type.typeName
			let headerViewController = self.storyboard!.instantiateViewController(withIdentifier: "NCDatabaseTypeInfoHeaderViewControllerSmall") as! NCDatabaseTypeInfoHeaderViewController
			headerViewController.type = type
			
			var frame = CGRect.zero
			frame.size = headerViewController.view.systemLayoutSizeFitting(CGSize(width: view.bounds.size.width, height:0), withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel)
			headerViewController.view.frame = frame
			tableView.tableHeaderView = UIView(frame: frame)
			tableView.addSubview(headerViewController.view)
			addChildViewController(headerViewController)
			self.headerViewController = headerViewController
			
			NCDataManager().image(typeID: Int(type.typeID), dimension: 512).then(on: .main) { value in
				let to = self.storyboard!.instantiateViewController(withIdentifier: "NCDatabaseTypeInfoHeaderViewControllerLarge") as! NCDatabaseTypeInfoHeaderViewController
				to.type = type
				to.image = value
				var frame = CGRect.zero
				frame.size = to.view.systemLayoutSizeFitting(CGSize(width: self.view.bounds.size.width, height:0), withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel)
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
				self.headerViewController = to
			}
			
			if marketQuickItem == nil {
				if type.marketGroup != nil {
					navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "favoritesOff"), style: .plain, target: self, action: #selector(onFavorites(_:)))
				}
			}
			else {
				navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "favoritesOn"), style: .plain, target: self, action: #selector(onFavorites(_:)))
			}
			
		}
		else {
			title = NSLocalizedString("Unknown", comment: "")
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(didChangeMarketRegion(_:)), name: .NCMarketRegionChanged, object: nil)
	}
	
	override func content() -> Future<TreeNode?> {
		guard let type = type else {
			return .init(nil)
		}
		return NCDatabaseTypeInfo.typeInfo(type: type, attributeValues: attributeValues).then { result in
			return RootNode(result, collapseIdentifier: "NCDatabaseTypeInfoViewController")
		}
	}
	
	var marketQuickItem: NCMarketQuickItem? {
		guard let typeID = self.type?.typeID else {return nil}
		return NCStorage.sharedStorage?.viewContext.fetch("MarketQuickItem", where: "typeID == %d", typeID)
	}
	
	@IBAction func onFavorites(_ sender: Any) {
		if let marketQuickItem = self.marketQuickItem {
			navigationItem.setRightBarButton(UIBarButtonItem(image: #imageLiteral(resourceName: "favoritesOff"), style: .plain, target: self, action: #selector(onFavorites(_:))), animated: true)
			marketQuickItem.managedObjectContext?.delete(marketQuickItem)
			if marketQuickItem.managedObjectContext?.hasChanges == true {
//				marketQuickItem.managedObjectContext?.processPendingChanges()
				try? marketQuickItem.managedObjectContext?.save()
			}
		}
		else if let context = NCStorage.sharedStorage?.viewContext, let type = self.type {
			navigationItem.setRightBarButton(UIBarButtonItem(image: #imageLiteral(resourceName: "favoritesOn"), style: .plain, target: self, action: #selector(onFavorites(_:))), animated: true)
			let marketQuickItem = NCMarketQuickItem(entity: NSEntityDescription.entity(forEntityName: "MarketQuickItem", in: context)!, insertInto: context)
			marketQuickItem.typeID = type.typeID
			if context.hasChanges {
				try? context.save()
			}
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		if let headerViewController = headerViewController {
			DispatchQueue.main.async {
				var frame = CGRect.zero
				frame.size = headerViewController.view.systemLayoutSizeFitting(CGSize(width: size.width, height:0), withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel)
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
	
	// MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		if let row = node as? NCDatabaseTrainingSkillRow {
			guard NCAccount.current != nil else {return}
			guard let skill = row.skill else {return}
			guard let type = NCDatabase.sharedDatabase?.invTypes[skill.skill.typeID] else {return}
			
			let trainingQueue = NCTrainingQueue(character: row.character)
			trainingQueue.add(skill: type, level: skill.level)
			performTraining(trainingQueue: trainingQueue, character: row.character, sender: treeController.cell(for: node))
		}
	}
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		if let item = node as? NCDatabaseSkillsSection {
			performTraining(trainingQueue: item.trainingQueue, character: item.character, sender: treeController.cell(for: node))
		}
	}
	
	// MARK: UIViewControllerPreviewingDelegate
	
	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard let indexPath = tableView.indexPathForRow(at: location) else {return nil}
		guard let item = treeController?.node(for: indexPath) else {return nil}
		return targetController(forItem: item)
	}
	
	func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		show(viewControllerToCommit, sender: self)
	}
	
	// MARK: Private
	
	private func performTraining(trainingQueue: NCTrainingQueue, character: NCCharacter, sender: UITableViewCell?) {
		guard let account = NCAccount.current else {return}
		
		let message = String(format: NSLocalizedString("Total Training Time: %@", comment: ""), NCTimeIntervalFormatter.localizedString(from: trainingQueue.trainingTime(characterAttributes: character.attributes), precision: .seconds))

		let controller = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Add to Skill Plan", comment: ""), style: .default) { [weak self] _ in
			account.activeSkillPlan?.add(trainingQueue: trainingQueue)
			
			if account.managedObjectContext?.hasChanges == true {
				try? account.managedObjectContext?.save()
				self?.tableView.reloadData()
			}
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
		present(controller, animated: true)
		controller.popoverPresentationController?.sourceView = sender
		controller.popoverPresentationController?.sourceRect = sender?.bounds ?? .zero

	}
	
	@objc private func didChangeMarketRegion(_ note: Notification) {
		if let type = type {
			NCDatabaseTypeInfo.typeInfo(type: type, attributeValues: attributeValues) { result in
				self.treeController?.content?.children = result
			}
		}
	}
	
	func targetController(forItem item: AnyObject) -> UIViewController? {
		return (item as? TreeNodeRoutable)?.route?.instantiateViewController()
//		let segue = (item as? NCDatabaseTypeInfoRow)?.segue
//		switch (item, segue) {
//		case (is NCDatabaseTypeMarketRow, _), (_, "NCDatabaseMarketInfoViewController"?):
//			let controller = self.storyboard?.instantiateViewController(withIdentifier: "NCDatabaseMarketInfoViewController") as! NCDatabaseMarketInfoViewController
//			controller.type = type
//			return controller
//		case (is NCDatabaseTypeSkillRow, _), (_, "NCDatabaseTypeInfoViewController"?):
//			let controller = self.storyboard?.instantiateViewController(withIdentifier: "NCDatabaseTypeInfoViewController") as! NCDatabaseTypeInfoViewController
//			let object = item.object as! NSManagedObjectID
//			controller.type = try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: object) as! NCDBInvType
//			return controller
//		case (_, "NCDatabaseTypesViewController"?):
//			let controller = self.storyboard?.instantiateViewController(withIdentifier: "NCDatabaseTypesViewController") as! NCDatabaseTypesViewController
//			let object = item.object as! NSManagedObjectID
//			let group = try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: object) as! NCDBInvGroup
//				controller.predicate = NSPredicate(format: "group = %@", group!)
//			controller.title = group!.groupName
//			return controller
//		case (_, "NCDatabaseCertificateMasteryViewController"?):
//			let controller = self.storyboard?.instantiateViewController(withIdentifier: "NCDatabaseCertificateMasteryViewController") as! NCDatabaseCertificateMasteryViewController
//			let object = item.object as! NSManagedObjectID
//			let level = try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: object) as! NCDBCertMasteryLevel
//			controller.type = type
//			controller.level = level
//			return controller
//		default:
//			return nil
//		}
	}
	
}


