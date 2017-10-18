//
//  NCMarketQuickbarViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData


class NCMarketQuickbarViewController: NCTreeViewController {
	
	var observer: NCEntityObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCModuleTableViewCell.default,
		                    Prototype.NCShipTableViewCell.default,
		                    Prototype.NCChargeTableViewCell.default,
		                    ])
		
		if let context = NCStorage.sharedStorage?.viewContext, let entity = NSEntityDescription.entity(forEntityName: "MarketQuickItem", in: context) {
			observer = NCEntityObserver(entity: entity, managedObjectContext: context) { [weak self] in
				guard let strongSelf = self else {return}
				if strongSelf.view.window == nil {
					strongSelf.treeController?.content = nil
				}
				else {
					NSObject.cancelPreviousPerformRequests(withTarget: strongSelf, selector: #selector(NCMarketQuickbarViewController.delayedUpdate), object: nil)
					strongSelf.perform(#selector(NCMarketQuickbarViewController.delayedUpdate), with: nil, afterDelay: 0)
				}
			}
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		defer {
			tableView.backgroundView =  treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
		
		
		guard let items: [NCMarketQuickItem] = NCStorage.sharedStorage?.viewContext.fetch("MarketQuickItem") else {return}
		
		let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
		request.predicate = NSPredicate(format: "typeID IN %@", items.map{$0.typeID})
		request.sortDescriptors = [NSSortDescriptor(key: "group.category.categoryName", ascending: true), NSSortDescriptor(key: "typeName", ascending: true)]
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: "group.category.categoryName", cacheName: nil)
		
		treeController?.content = FetchedResultsNode(resultsController: results, sectionNode: NCDefaultFetchedResultsSectionNode<NCDBInvType>.self, objectNode: NCDatabaseTypeRow<NCDBInvType>.self)
	}
	
	@objc private func delayedUpdate() {
		updateContent {}
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCDatabaseTypeRow<NCDBInvType> else {return}
		Router.Database.TypeInfo(row.object).perform(source: self, sender: treeController.cell(for: node))
	}

}
