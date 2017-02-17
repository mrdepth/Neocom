//
//  NCFittingDamagePatternsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFittingDamagePatternInfoRow: NCFittingDamagePatternRow {
	let name: String
	init(damagePattern: NCFittingDamage, name: String) {
		self.name = name
		super.init(damagePattern: damagePattern)
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDamageTypeTableViewCell else {return}
		cell.titleLabel?.text = name
	}
}

class NCAddDamagePatternRow: DefaultTreeRow {
	init() {
		super.init(cellIdentifier: "NCDefaultTableViewCell", title: NSLocalizedString("Add Damage Pattern", comment: ""))
	}
}

class NCPredefinedDamagePatternsSection: DefaultTreeSection {
	init() {
		let predefined = NSArray(contentsOf: Bundle.main.url(forResource: "damagePatterns", withExtension: "plist")!)?.flatMap { item -> NCFittingDamagePatternInfoRow? in
			guard let item = item as? [String: Any] else {return nil}
			guard let name = item["name"] as? String else {return nil}
			guard let em = item["em"] as? Double else {return nil}
			guard let thermal = item["thermal"] as? Double else {return nil}
			guard let kinetic = item["kinetic"] as? Double else {return nil}
			guard let explosive = item["explosive"] as? Double else {return nil}
			let vector = NCFittingDamage(em: em, thermal: thermal, kinetic: kinetic, explosive: explosive)
			return NCFittingDamagePatternInfoRow(damagePattern: vector, name: name)
		}

		super.init(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Predefined", title: NSLocalizedString("Predefined", comment: "").uppercased(), children: predefined!)
	}
	
	override var hashValue: Int {
		return 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCPredefinedDamagePatternsSection)?.hashValue == hashValue
	}

}

class NCCustomDamagePatternsSection: FetchedResultsNode<NCDamagePattern> {
	
	init(managedObjectContext: NSManagedObjectContext) {
		let request = NSFetchRequest<NCDamagePattern>(entityName: "DamagePattern")
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		try? controller.performFetch()
		super.init(resultsController: controller, objectNode: NCCustomDamagePatternRow.self)
		cellIdentifier = "NCHeaderTableViewCell"
	}
	
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCHeaderTableViewCell {
			cell.object = self
			cell.titleLabel?.text = NSLocalizedString("Custom", comment: "").uppercased()
		}
	}
	
	override var isExpandable: Bool {
		return true
	}
	
	override var hashValue: Int {
		return #line
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCCustomDamagePatternsSection)?.hashValue == hashValue
	}
}

class NCCustomDamagePatternRow: FetchedResultsObjectNode<NCDamagePattern> {

	private lazy var editingContext: NSManagedObjectContext = {
		let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.parent = self.object.managedObjectContext
		return context
	}()
	
	private lazy var editingObject: NCDamagePattern? = {
		return self.editingContext.object(with: self.object.objectID) as? NCDamagePattern
	}()
	
	private var changed: Bool = false
	
	var isEditing: Bool = false {
		didSet {
			guard isEditing != oldValue else {return}
			guard let editingObject = editingObject else {return}
			changed = true
			if isEditing {
				children = [NCDamagePatternEditRow(damagePattern: editingObject)]
				cellIdentifier = "NCTextFieldTableViewCell"
			}
			else {
				let total = editingObject.em + editingObject.thermal + editingObject.kinetic + editingObject.explosive
				if (total > 0) {
					editingObject.em /= total
					editingObject.thermal /= total
					editingObject.kinetic /= total
					editingObject.explosive /= total
					
				}
				else {
					editingObject.em = 0.25
					editingObject.thermal = 0.25
					editingObject.kinetic = 0.25
					editingObject.explosive = 0.25
				}
				children = []
				try? editingContext.save()
				cellIdentifier = "NCDamageTypeTableViewCell"
			}
			//self.cellIdentifier = isEditing ? "NCDamagePatternEditTableViewCell" : "NCDamageTypeTableViewCell"
		}
	}
	
	override func move(from: TreeNode) -> TreeNodeReloading {
		
		guard let from = from as? NCCustomDamagePatternRow else {return .dontReload}
		let changed = from.changed
		self.changed = false
		editingContext = from.editingContext
		editingObject = from.editingObject
		isEditing = from.isEditing
		return changed ? .reload : .dontReload
	}
	
	required init(object: NCDamagePattern) {
		super.init(object: object)
		self.cellIdentifier = "NCDamageTypeTableViewCell"
	}
	
	private var handler: NCActionHandler?

	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCDamageTypeTableViewCell {
			cell.titleLabel?.text = object.name?.isEmpty == false ? object.name : " "
			
			func fill(label: NCDamageTypeLabel, value: Double) {
				label.progress = Float(value)
				label.text = "\(Int(round(value * 100)))%"
			}
			
			fill(label: cell.emLabel, value: Double(object.em))
			fill(label: cell.kineticLabel, value: Double(object.kinetic))
			fill(label: cell.thermalLabel, value: Double(object.thermal))
			fill(label: cell.explosiveLabel, value: Double(object.explosive))
		}
		else if let cell = cell as? NCTextFieldTableViewCell {
			let textField = cell.textField
			textField?.text = editingObject?.name
			handler = NCActionHandler(cell.textField, for: .editingChanged, handler: { [weak self] _ in
				self?.editingObject?.name = textField?.text
				//self?.text = textField?.text
			})
		}
	}

}


class NCFittingDamagePatternsViewController: UITableViewController, TreeControllerDelegate, UITextFieldDelegate {
	@IBOutlet var treeController: TreeController!
	var category: NCDBDgmppItemCategory?
	var completionHandler: ((NCFittingDamage) -> Void)!
	
	lazy private var managedObjectContext: NSManagedObjectContext? = {
		guard let parentContext = NCStorage.sharedStorage?.viewContext else {return nil}
		let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.parent = parentContext
		return context
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		navigationItem.rightBarButtonItem = editButtonItem
		
		var sections = [TreeNode]()
		
		if let managedObjectContext = self.managedObjectContext {
			sections.append(NCCustomDamagePatternsSection(managedObjectContext: managedObjectContext))
		}
		sections.append(NCPredefinedDamagePatternsSection())
		
		let root = TreeNode()
		root.children = sections
		self.treeController.rootNode = root
		
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		guard isEditing != editing else {return}
		super.setEditing(editing, animated: animated)
		guard let i = treeController.rootNode?.children?.index(where: {$0 is NCCustomDamagePatternsSection}) else {return}
		if editing {
			treeController.rootNode?.children?.insert(NCAddDamagePatternRow(), at: i + 1)
		}
		else {
			let section = treeController.rootNode?.children?.first(where: {$0 is NCCustomDamagePatternsSection})
			if let editingNode = section?.children?.first(where: {($0 as? NCCustomDamagePatternRow)?.isEditing == true}) as? NCCustomDamagePatternRow {
				editingNode.isEditing = false
			}
			try? managedObjectContext?.save()
			try? managedObjectContext?.parent?.save()
			treeController.rootNode?.children?.remove(at: i + 1)
		}
	}
	
	@IBAction func onDone(_ sender: UIButton) {
		guard let cell = sender.ancestor(of: UITableViewCell.self) else {return}
		guard let node = treeController.node(for: cell) as? NCCustomDamagePatternRow else {return}
		node.isEditing = false
		treeController.reloadCells(for: [node])
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		treeController.deselectCell(for: node, animated: true)
		if isEditing {
			switch node {
			case let node as NCCustomDamagePatternRow:
				let editingNode = node.parent?.children?.first(where: {($0 as? NCCustomDamagePatternRow)?.isEditing == true}) as? NCCustomDamagePatternRow
				
				if let editingNode = editingNode, editingNode != node {
					editingNode.isEditing = false
					treeController.reloadCells(for: [editingNode])
					//node.isEditing = true
				}
				else {
					node.isEditing = !node.isEditing
					treeController.reloadCells(for: [node])
				}
				guard let cell = treeController.cell(for: node) as? NCTextFieldTableViewCell else {return}
				cell.textField.becomeFirstResponder()
			case is NCAddDamagePatternRow:
				addDamagePattern()
//			case let node as NCFittingDamagePatternInfoRow:
//				addDamagePattern(damagePattern: node.damagePattern, name: node.name + " " + NSLocalizedString("Copy", comment: "Ex: Guristas Copy"))
			default:
				break
			}
		}
		else {
			switch node {
			case let node as NCCustomDamagePatternRow:
				completionHandler(NCFittingDamage(em: Double(node.object.em),
				                                  thermal: Double(node.object.thermal),
				                                  kinetic: Double(node.object.kinetic),
				                                  explosive: Double(node.object.explosive)))
			case let node as NCFittingDamagePatternInfoRow:
				completionHandler(node.damagePattern)
			default:
				break
			}
		}
	}
	
	func treeController(_ treeController: TreeController, editingStyleForNode node: TreeNode) -> UITableViewCellEditingStyle {
		switch node {
		case is NCAddDamagePatternRow:
			return .insert
		case is NCCustomDamagePatternRow, is NCFittingDamagePatternInfoRow:
			return .delete
		default:
			return .none
		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		switch node {
		case let node as NCCustomDamagePatternRow:
			return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { _ in
				self.treeController(self.treeController, commit: .delete, forNode: node)
			})]
		case let node as NCFittingDamagePatternInfoRow:
			return [UITableViewRowAction(style: .normal, title: NSLocalizedString("Duplicate", comment: ""), handler: { _ in
				self.addDamagePattern(damagePattern: node.damagePattern, name: node.name + " " + NSLocalizedString("Copy", comment: "Ex: Guristas Copy"))
			})]
		default:
			return nil
		}
	}
	
	func treeController(_ treeController: TreeController, commit editingStyle: UITableViewCellEditingStyle, forNode node: TreeNode) {
		guard let managedObjectContext = self.managedObjectContext else {return}

		switch editingStyle {
		case .insert:
			addDamagePattern()

		case .delete:
			guard let pattern = (node as? NCCustomDamagePatternRow)?.object else {return}
			managedObjectContext.delete(pattern)
			try? managedObjectContext.save()
		default:
			break
		}
	}
	
	//MARK: - UITextFieldDelegate
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.endEditing(true)
		return true
	}
	
	//MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCDatabaseTypeInfoViewController"?:
			guard let controller = segue.destination as? NCDatabaseTypeInfoViewController,
				let cell = sender as? NCTableViewCell,
				let type = cell.object as? NCDBInvType else {
					return
			}
			controller.type = type
		default:
			break
		}
	}
	
	//MARK: - Private
	
	private func addDamagePattern(damagePattern: NCFittingDamage = NCFittingDamage.omni, name: String = NSLocalizedString("Unnamed", comment: "")) {
		guard let managedObjectContext = self.managedObjectContext else {return}
		
		let pattern = NCDamagePattern(entity: NSEntityDescription.entity(forEntityName: "DamagePattern", in: managedObjectContext)!, insertInto: managedObjectContext)
		pattern.em = Float(damagePattern.em)
		pattern.explosive = Float(damagePattern.explosive)
		pattern.kinetic = Float(damagePattern.kinetic)
		pattern.thermal = Float(damagePattern.thermal)
		pattern.name = name
		try? managedObjectContext.save()
		
		let section = treeController.rootNode?.children?.first(where: {$0 is NCCustomDamagePatternsSection})
		if let node = section?.children?.first(where: {($0 as? NCCustomDamagePatternRow)?.object == pattern}) as? NCCustomDamagePatternRow {
			node.isEditing = true
			treeController.reloadCells(for: [node])
			if let indexPath = treeController.indexPath(for: node) {
				tableView.scrollToRow(at: indexPath, at: .top, animated: true)
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
				if let cell = self.treeController.cell(for: node) as? NCTextFieldTableViewCell {
					cell.textField.becomeFirstResponder()
				}
			}
		}

	}
}
