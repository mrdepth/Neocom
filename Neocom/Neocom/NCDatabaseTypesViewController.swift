//
//  NCDatabaseTypesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI

fileprivate class InvType<T> {
	
	let object: T
	
	init(_ object: T) {
		self.object = object
	}
	
	func requirements() -> NCDBDgmppItemRequirements? {
		return nil
	}
	
	func shipResources() -> NCDBDgmppItemShipResources? {
		return nil
	}
	
	func damage() -> NCDBDgmppItemDamage? {
		return nil
	}
	
	func icon() -> NCDBEveIcon? {
		return nil
	}
	
	func typeName() -> String? {
		return nil
	}
	
	func typeID() -> Int? {
		return nil
	}
	
	func prototype() -> Prototype? {
		return nil
	}
}

class NCDatabaseTypesSection: FetchedResultsNode<NSDictionary> {
	init(managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?, sectionNode: FetchedResultsSectionNode<NSDictionary>.Type? = nil, objectNode: NCFetchedResultsObjectNode<NSDictionary>.Type) {
		let request = NSFetchRequest<NSDictionary>(entityName: "InvType")
		request.predicate = predicate ?? NSPredicate(value: false)
		request.sortDescriptors = [
			NSSortDescriptor(key: "metaGroup.metaGroupID", ascending: true),
			NSSortDescriptor(key: "metaLevel", ascending: true),
			NSSortDescriptor(key: "typeName", ascending: true)]
		
		let entity = managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName[request.entityName!]!
		let propertiesByName = entity.propertiesByName
		var properties = [NSPropertyDescription]()
		properties.append(propertiesByName["typeID"]!)
		properties.append(propertiesByName["typeName"]!)
		properties.append(propertiesByName["metaLevel"]!)
		properties.append(NSExpressionDescription(name: "metaGroupID", resultType: .integer32AttributeType, expression: NSExpression(forKeyPath: "metaGroup.metaGroupID")))
		properties.append(NSExpressionDescription(name: "icon", resultType: .objectIDAttributeType, expression: NSExpression(forKeyPath: "icon")))
		properties.append(NSExpressionDescription(name: "metaGroupName", resultType: .stringAttributeType, expression: NSExpression(forKeyPath: "metaGroup.metaGroupName")))
		
		properties.append(NSExpressionDescription(name: "requirements", resultType: .objectIDAttributeType, expression: NSExpression(forKeyPath: "dgmppItem.requirements")))
		properties.append(NSExpressionDescription(name: "shipResources", resultType: .objectIDAttributeType, expression: NSExpression(forKeyPath: "dgmppItem.shipResources")))
		properties.append(NSExpressionDescription(name: "damage", resultType: .objectIDAttributeType, expression: NSExpression(forKeyPath: "dgmppItem.damage")))
		
		request.propertiesToFetch = properties
		request.resultType = .dictionaryResultType
		
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "metaGroupName", cacheName: nil)
		
		super.init(resultsController: results, sectionNode: sectionNode, objectNode: objectNode)
	}

}

class NCDatabaseTypeRow<ResultType: NSFetchRequestResult>: NCFetchedResultsObjectNode<ResultType>, TreeNodeRoutable {
	
	var route: Route?
	var accessoryButtonRoute: Route?
	
	lazy var requirements: NCDBDgmppItemRequirements? = {
		if let object = self.object as? NSDictionary {
			guard let context = NCDatabase.sharedDatabase?.viewContext else {return nil}
			guard let objectID = object["requirements"] as? NSManagedObjectID else {return nil}
			return (try? context.existingObject(with: objectID)) as? NCDBDgmppItemRequirements
		}
		else if let object = self.object as? NCDBInvType {
			return object.dgmppItem?.requirements
		}
		else {
			return nil
		}
	}()

	lazy var shipResources: NCDBDgmppItemShipResources? = {
		if let object = self.object as? NSDictionary {
			guard let context = NCDatabase.sharedDatabase?.viewContext else {return nil}
			guard let objectID = object["shipResources"] as? NSManagedObjectID else {return nil}
			return (try? context.existingObject(with: objectID)) as? NCDBDgmppItemShipResources
		}
		else if let object = self.object as? NCDBInvType {
			return object.dgmppItem?.shipResources
		}
		else {
			return nil
		}
	}()

	lazy var damage: NCDBDgmppItemDamage? = {
		if let object = self.object as? NSDictionary {
			guard let context = NCDatabase.sharedDatabase?.viewContext else {return nil}
			guard let objectID = object["damage"] as? NSManagedObjectID else {return nil}
			return (try? context.existingObject(with: objectID)) as? NCDBDgmppItemDamage
		}
		else if let object = self.object as? NCDBInvType {
			return object.dgmppItem?.damage
		}
		else {
			return nil
		}
	}()
	
	lazy var icon: NCDBEveIcon? = {
		if let object = self.object as? NSDictionary {
			guard let context = NCDatabase.sharedDatabase?.viewContext else {return nil}
			guard let objectID = object["icon"] as? NSManagedObjectID else {return nil}
			return (try? context.existingObject(with: objectID)) as? NCDBEveIcon
		}
		else if let object = self.object as? NCDBInvType {
			return object.icon
		}
		else {
			return nil
		}
	}()

	required init(object: ResultType) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.compact.reuseIdentifier
		
		if let object = self.object as? NSDictionary {
			if object["requirements"] != nil {
				cellIdentifier = Prototype.NCModuleTableViewCell.default.reuseIdentifier
			}
			else if object["shipResources"] != nil {
				cellIdentifier = Prototype.NCShipTableViewCell.default.reuseIdentifier
			}
			else if object["damage"] != nil {
				cellIdentifier = Prototype.NCChargeTableViewCell.default.reuseIdentifier
			}
		}
		else if let object = self.object as? NCDBInvType {
			if object.dgmppItem?.requirements != nil {
				cellIdentifier = Prototype.NCModuleTableViewCell.default.reuseIdentifier
			}
			else if object.dgmppItem?.shipResources != nil {
				cellIdentifier = Prototype.NCShipTableViewCell.default.reuseIdentifier
			}
			else if object.dgmppItem?.damage != nil {
				cellIdentifier = Prototype.NCChargeTableViewCell.default.reuseIdentifier
			}
		}
	}
	
	override func configure(cell: UITableViewCell) {
		let typeName = (object as? NSDictionary)?["typeName"] as? String ?? (object as? NCDBInvType)?.typeName

		if let requirements = requirements {
			guard let cell = cell as? NCModuleTableViewCell else {return}
			cell.titleLabel?.text = typeName
			cell.iconView?.image = icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.accessoryType = .disclosureIndicator
			cell.cpuLabel.text = NCUnitFormatter.localizedString(from: requirements.cpu, unit: .teraflops, style: .full)
			cell.powerGridLabel.text = NCUnitFormatter.localizedString(from: requirements.powerGrid, unit: .megaWatts, style: .full)
		}
		else if let shipResources = shipResources {
			guard let cell = cell as? NCShipTableViewCell else {return}
			cell.titleLabel?.text = typeName
			cell.iconView?.image = icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.accessoryType = .disclosureIndicator
			cell.hiSlotsLabel.text = "\(shipResources.hiSlots)"
			cell.medSlotsLabel.text = "\(shipResources.medSlots)"
			cell.lowSlotsLabel.text = "\(shipResources.lowSlots)"
			cell.rigSlotsLabel.text = "\(shipResources.rigSlots)"
			cell.turretsLabel.text = "\(shipResources.turrets)"
			cell.launchersLabel.text = "\(shipResources.launchers)"
		}
		else if let damage = damage {
			guard let cell = cell as? NCChargeTableViewCell else {return}
			cell.titleLabel?.text = typeName
			cell.iconView?.image = icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.accessoryType = .disclosureIndicator
			
			var total = damage.emAmount + damage.kineticAmount + damage.thermalAmount + damage.explosiveAmount
			if total == 0 {
				total = 1
			}
			
			cell.emLabel.progress = damage.emAmount / total
			cell.emLabel.text = NCUnitFormatter.localizedString(from: damage.emAmount, unit: .none, style: .short)
			
			cell.kineticLabel.progress = damage.kineticAmount / total
			cell.kineticLabel.text = NCUnitFormatter.localizedString(from: damage.kineticAmount, unit: .none, style: .short)
			
			cell.thermalLabel.progress = damage.thermalAmount / total
			cell.thermalLabel.text = NCUnitFormatter.localizedString(from: damage.thermalAmount, unit: .none, style: .short)
			
			cell.explosiveLabel.progress = damage.explosiveAmount / total
			cell.explosiveLabel.text = NCUnitFormatter.localizedString(from: damage.explosiveAmount, unit: .none, style: .short)
		}
		else {
			guard let cell = cell as? NCDefaultTableViewCell else {return}
			cell.titleLabel?.text = typeName
			cell.iconView?.image = icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.accessoryType = .disclosureIndicator
		}
	}
	
	override var hashValue: Int {
		return (object as? NSDictionary)?["typeID"] as? Int ?? Int((object as? NCDBInvType)?.typeID ?? 0)
	}
}


class NCDatabaseTypesViewController: NCTreeViewController, NCSearchableViewController {
	
	private let gate = NCGate()
	var predicate: NSPredicate?

	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCModuleTableViewCell.default,
		                    Prototype.NCShipTableViewCell.default,
		                    Prototype.NCChargeTableViewCell.default,
		                    ])
		
		if navigationController != nil {
			setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCDatabaseTypesViewController"))
		}
	}
	
	private let root = TreeNode()
	
	override func content() -> Future<TreeNode?> {
		reloadData()
		return .init(root)
	}
	
	func reloadData() {
		gate.perform {
			NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
				let section = NCDatabaseTypesSection(managedObjectContext: managedObjectContext, predicate: self.predicate, sectionNode: NCDefaultFetchedResultsSectionNode<NSDictionary>.self, objectNode: NCDatabaseTypeRow<NSDictionary>.self)
				try? section.resultsController.performFetch()
				
				DispatchQueue.main.async {
					self.root.children = [section]
					self.tableView.backgroundView = (section.resultsController.fetchedObjects?.count ?? 0) == 0 ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
				}
			})
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController?.content = nil
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCDatabaseTypeRow<NSDictionary> else {return}
		guard let typeID = row.object["typeID"] as? Int else {return}
		Router.Database.TypeInfo(typeID).perform(source: self, sender: treeController.cell(for: node))
	}
	
	//MARK: NCSearchableViewController
	
	var searchController: UISearchController?

	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCDatabaseTypesViewController else {return}
		if let text = searchController.searchBar.text, let other = self.predicate, text.count > 2 {
			predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [other, NSPredicate(format: "typeName CONTAINS[C] %@", text)])
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	
}
