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
		super.init(prototype: Prototype.NCDamageTypeTableViewCell.default, damagePattern: damagePattern)
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDamageTypeTableViewCell else {return}
		cell.titleLabel?.text = name
	}
}

class NCAddDamagePatternRow: NCActionRow {
	init() {
		super.init(title: NSLocalizedString("Add Damage Pattern", comment: ""))
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

		super.init(nodeIdentifier: "Predefined", title: NSLocalizedString("Predefined", comment: "").uppercased(), children: predefined!)
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
		isExpandable = true
	}
	
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCHeaderTableViewCell {
			cell.object = self
			cell.titleLabel?.text = NSLocalizedString("Custom", comment: "").uppercased()
		}
	}
	
	override func loadChildren() {
		super.loadChildren()
		children.append(NCAddDamagePatternRow())
	}
	
	override var hashValue: Int {
		return #line
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCCustomDamagePatternsSection)?.hashValue == hashValue
	}
}

class NCCustomDamagePatternRow: NCFetchedResultsObjectNode<NCDamagePattern> {

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
				cellIdentifier = Prototype.NCTextFieldTableViewCell.default.reuseIdentifier
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
				cellIdentifier = Prototype.NCDamageTypeTableViewCell.default.reuseIdentifier
				children = []
				try? editingContext.save()
			}
		}
	}
	
	override func update(from node: TreeNode) {
		super.update(from: node)
		guard let from = node as? NCCustomDamagePatternRow else {return}
//		let changed = from.changed
		self.changed = false
		editingContext = from.editingContext
		editingObject = from.editingObject
		isEditing = from.isEditing
	}
	
	required init(object: NCDamagePattern) {
		super.init(object: object)
		self.cellIdentifier = Prototype.NCDamageTypeTableViewCell.default.reuseIdentifier
		isExpandable = false
	}
	
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
//			cell.backgroundColor = .background
			textField?.text = editingObject?.name
			cell.handlers[.editingChanged] = NCActionHandler(cell.textField, for: .editingChanged, handler: { [weak self] _ in
				self?.editingObject?.name = textField?.text
				//self?.text = textField?.text
			})
		}
	}

}


class NCFittingDamagePatternsViewController: NCTreeViewController, UITextFieldDelegate {

	var category: NCDBDgmppItemCategory?
	var completionHandler: ((NCFittingDamagePatternsViewController, NCFittingDamage) -> Void)!
	
	lazy private var managedObjectContext: NSManagedObjectContext? = {
		guard let parentContext = NCStorage.sharedStorage?.viewContext else {return nil}
		let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.parent = parentContext
		return context
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDamageTypeTableViewCell.default,
		                    Prototype.NCActionTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default])
		
		navigationItem.rightBarButtonItem = editButtonItem
		
		var sections = [TreeNode]()
		
		
		sections.append(NCActionRow(title: NSLocalizedString("Select NPC Type", comment: ""), attributedTitle: nil, route: Router.Database.NPCPicker { [weak self] (controller, type) in
			controller.dismiss(animated: true, completion: nil)
			self?.select(npc: type)
		}))
		
		if let managedObjectContext = self.managedObjectContext {
			sections.append(NCCustomDamagePatternsSection(managedObjectContext: managedObjectContext))
		}
		
		//sections.append(NCAddDamagePatternRow())
		
		sections.append(NCPredefinedDamagePatternsSection())
		
		let root = TreeNode()
		root.children = sections
		self.treeController?.content = root
		
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		if !editing {
			try? managedObjectContext?.save()
			try? managedObjectContext?.parent?.save()
		}
	}
	
	@IBAction func onDone(_ sender: UIButton) {
		guard let cell = sender.ancestor(of: UITableViewCell.self) else {return}
		guard let node = treeController?.node(for: cell) as? NCCustomDamagePatternRow else {return}
		node.isEditing = false
		treeController?.reloadCells(for: [node])
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		if isEditing {
			switch node {
			case let node as NCCustomDamagePatternRow:
				let editingNode = node.parent?.children.first(where: {($0 as? NCCustomDamagePatternRow)?.isEditing == true}) as? NCCustomDamagePatternRow
				
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
				if let indexPath = tableView.indexPath(for: cell) {
					tableView.scrollToRow(at: indexPath, at: .top, animated: true)
				}
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
				completionHandler(self, NCFittingDamage(em: Double(node.object.em),
				                                  thermal: Double(node.object.thermal),
				                                  kinetic: Double(node.object.kinetic),
				                                  explosive: Double(node.object.explosive)))
			case let node as NCFittingDamagePatternInfoRow:
				completionHandler(self, node.damagePattern)
			case is NCAddDamagePatternRow:
				addDamagePattern()
			default:
				break
			}
		}
	}
	
	func treeController(_ treeController: TreeController, editingStyleForNode node: TreeNode) -> UITableViewCellEditingStyle {
		switch node {
//		case is NCAddDamagePatternRow:
//			return .insert
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
				guard let controller = self.treeController else {return}
				self.treeController(controller, commit: .delete, forNode: node)
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
			try? managedObjectContext.parent?.save()
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
	
	private func select(npc: NCDBInvType) {
		let attributes = npc.allAttributes
		
		let turrets: (Float, Float, Float, Float) = {
			let damage = (attributes[NCDBAttributeID.emDamage.rawValue]?.value ?? 0,
			              attributes[NCDBAttributeID.thermalDamage.rawValue]?.value ?? 0,
			              attributes[NCDBAttributeID.kineticDamage.rawValue]?.value ?? 0,
			              attributes[NCDBAttributeID.explosiveDamage.rawValue]?.value ?? 0)
			
			let multiplier = attributes[NCDBAttributeID.damageMultiplier.rawValue]?.value ?? 1
			let rof = (attributes[NCDBAttributeID.speed.rawValue]?.value ?? 1000) / 1000
			return (damage.0 * multiplier / rof, damage.1 * multiplier / rof, damage.2 * multiplier / rof, damage.3 * multiplier / rof)
		}()
		
		let launchers: (Float, Float, Float, Float) = {
			guard let missileID = attributes[NCDBAttributeID.entityMissileTypeID.rawValue]?.value, let missile = NCDatabase.sharedDatabase?.invTypes[Int(missileID)] else {return (0,0,0,0)}
			let attributes = missile.allAttributes
			let damage = (attributes[NCDBAttributeID.emDamage.rawValue]?.value ?? 0,
			              attributes[NCDBAttributeID.thermalDamage.rawValue]?.value ?? 0,
			              attributes[NCDBAttributeID.kineticDamage.rawValue]?.value ?? 0,
			              attributes[NCDBAttributeID.explosiveDamage.rawValue]?.value ?? 0)
			
			let multiplier = attributes[NCDBAttributeID.missileDamageMultiplier.rawValue]?.value ?? 1
			let rof = (attributes[NCDBAttributeID.missileLaunchDuration.rawValue]?.value ?? 1000) / 1000
			guard rof > 0 else {return (0,0,0,0)}
			return (damage.0 * multiplier / rof, damage.1 * multiplier / rof, damage.2 * multiplier / rof, damage.3 * multiplier / rof)
		}()
		
		let dps = (turrets.0 + launchers.0, turrets.1 + launchers.1, turrets.2 + launchers.2, turrets.3 + launchers.3)
		let totalDPS = dps.0 + dps.1 + dps.2 + dps.3
		
		if totalDPS > 0 {
			completionHandler(self, NCFittingDamage(em: Double(dps.0 / totalDPS),
			                                        thermal: Double(dps.1 / totalDPS),
			                                        kinetic: Double(dps.2 / totalDPS),
			                                        explosive: Double(dps.3 / totalDPS)))
		}
		else {
			completionHandler(self, NCFittingDamage(em: Double(0.25),
			                                        thermal: Double(0.25),
			                                        kinetic: Double(0.25),
			                                        explosive: Double(0.25)))
		}
	}
	
	private func addDamagePattern(damagePattern: NCFittingDamage = NCFittingDamage.omni, name: String = NSLocalizedString("Unnamed", comment: "")) {
		guard let managedObjectContext = self.managedObjectContext else {return}
		
		let pattern = NCDamagePattern(entity: NSEntityDescription.entity(forEntityName: "DamagePattern", in: managedObjectContext)!, insertInto: managedObjectContext)
		pattern.em = Float(damagePattern.em)
		pattern.explosive = Float(damagePattern.explosive)
		pattern.kinetic = Float(damagePattern.kinetic)
		pattern.thermal = Float(damagePattern.thermal)
		pattern.name = name
		try? managedObjectContext.save()
		
		let section = treeController?.content?.children.first(where: {$0 is NCCustomDamagePatternsSection})
		if section?.isExpanded == false {
			section?.isExpanded = true
		}
		
		if let node = section?.children.first(where: {($0 as? NCCustomDamagePatternRow)?.object == pattern}) as? NCCustomDamagePatternRow {
			node.isEditing = true
			treeController?.reloadCells(for: [node])
			if let indexPath = treeController?.indexPath(for: node) {
				tableView.scrollToRow(at: indexPath, at: .top, animated: true)
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
				if let cell = self.treeController?.cell(for: node) as? NCTextFieldTableViewCell {
					cell.textField.becomeFirstResponder()
				}
			}
		}

	}
}
