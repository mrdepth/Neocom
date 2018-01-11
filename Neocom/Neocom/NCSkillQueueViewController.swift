//
//  NCSkillQueueViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI
import CloudData


fileprivate class NCSkillQueueRow: NCSkillRow {

	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCSkillTableViewCell else {return}
		
		cell.iconView?.image = nil
		cell.titleLabel?.text = "\(skill.typeName) (x\(Int(skill.rank)))"
		let level = min(1 + (skill.level ?? 0), 5)
//		cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:min(1 + (skill.level ?? 0), 5))
		cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:level)
		cell.skillLevelView?.level = level
		cell.skillLevelView?.isActive = skill.isActive
		
		cell.progressView?.progress = skill.trainingProgress
		
		let a = NCUnitFormatter.localizedString(from: Double(skill.skillPoints), unit: .none, style: .full)
		let b = NCUnitFormatter.localizedString(from: Double(skill.skillPoints(at: 1 + (skill.level ?? 0))), unit: .skillPoints, style: .full)

		let sph = Int((character.attributes.skillpointsPerSecond(forSkill: skill) * 3600).rounded())
		cell.spLabel?.text = "\(a) / \(b) (\(NCUnitFormatter.localizedString(from: sph, unit: .custom(NSLocalizedString("SP/h", comment: ""), false), style: .full)))"
		if let from = skill.trainingStartDate, let to = skill.trainingEndDate {
			cell.trainingTimeLabel?.text = NCTimeIntervalFormatter.localizedString(from: max(to.timeIntervalSince(max(from, Date())), 0), precision: .minutes)
		}
		else {
			cell.trainingTimeLabel?.text = nil
		}
	}
	
	override var hashValue: Int {
		return skill.hashValue
	}
	
	static func ==(lhs: NCSkillQueueRow, rhs: NCSkillQueueRow) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}

fileprivate class NCSkillPlanSkillRow: NCFetchedResultsObjectNode<NCSkillPlanSkill>, TreeNodeRoutable {
	var skill: NCTrainingSkill?
	var character: NCCharacter?
	
	var route: Route?
	var accessoryButtonRoute: Route?
	
	required init(object: NCSkillPlanSkill) {
		super.init(object: object)
		cellIdentifier = Prototype.NCSkillTableViewCell.default.reuseIdentifier
		route = Router.Database.TypeInfo(Int(object.typeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCSkillTableViewCell else {return}
		if let character = character, let skill = skill {
			cell.titleLabel?.text = "\(skill.skill.typeName) (x\(Int(skill.skill.rank)))"
			
			let level = min(skill.level, 5)
//			cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:min(skill.level, 5))
			cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:level)
			cell.skillLevelView?.level = level
			cell.skillLevelView?.isActive = skill.skill.isActive
			
			let a = NCUnitFormatter.localizedString(from: Double(skill.skill.skillPoints), unit: .none, style: .full)
			let b = NCUnitFormatter.localizedString(from: Double(skill.skill.skillPoints(at: skill.level)), unit: .skillPoints, style: .full)
			
			let sph = Int((character.attributes.skillpointsPerSecond(forSkill: skill.skill) * 3600).rounded())
			cell.spLabel?.text = "\(a) / \(b) (\(NCUnitFormatter.localizedString(from: sph, unit: .custom(NSLocalizedString("SP/h", comment: ""), false), style: .full)))"

			let t = skill.trainingTime(characterAttributes: character.attributes)
			cell.trainingTimeLabel?.text = NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes)
		}
		else {
			cell.titleLabel?.text =	NSLocalizedString("Unknown Type", comment: "")
			cell.levelLabel?.text = nil
			cell.trainingTimeLabel?.text = " "
			cell.spLabel?.text = " "
			cell.skillLevelView?.level = 0
			cell.skillLevelView?.isActive = false
		}
		cell.iconView?.image = #imageLiteral(resourceName: "skillRequirementQueued")
		
		cell.progressView?.progress = 0
	}
	
}

fileprivate class NCSkillQueueSection: DefaultTreeSection {
	var observer: NotificationObserver?
	let character: NCCharacter
	
	init(character: NCCharacter) {
		self.character = character
		
		let invTypes = NCDatabase.sharedDatabase?.invTypes
		func rows(_ skillQueue: [ESI.Skills.SkillQueueItem]) -> [NCSkillQueueRow] {
			let date = Date()
			return skillQueue.flatMap { (item) in
				guard let finishDate = item.finishDate, finishDate > date else {return nil}
				guard let type = invTypes?[item.skillID] else {return nil}
				guard let skill = NCSkill(type: type, skill: item) else {return nil}
				return NCSkillQueueRow(skill: skill, character: character)
			}
		}

		let children = rows(character.skillQueue)
		
		func title(_ skillQueue: [ESI.Skills.SkillQueueItem], count: Int) -> String {
			if let lastSkill = skillQueue.last, let endDate = lastSkill.finishDate, endDate > Date() {
				return String(format: NSLocalizedString("SKILL QUEUE: %@ (%d skills)", comment: ""),
				                               NCTimeIntervalFormatter.localizedString(from: max(0, endDate.timeIntervalSinceNow), precision: .minutes), count)
			}
			else {
				return NSLocalizedString("No skills in training", comment: "").uppercased()
			}
		}
		

		super.init(nodeIdentifier: "SkillQueue", title: title(character.skillQueue, count: children.count), children: children)

		observer = NotificationCenter.default.addNotificationObserver(forName: .NCCharacterChanged, object: character, queue: .main) {[weak self] note in
			guard let strongSelf = self else {return}
			
			let to = rows(character.skillQueue)
			strongSelf.children = to
			strongSelf.title = title(character.skillQueue, count: to.count)
		}

	}
}

fileprivate class NCSKillPlanSkillsNode: FetchedResultsNode<NCSkillPlanSkill> {
	
	init(skillPlan: NCSkillPlan, character: NCCharacter) {
		let request = NSFetchRequest<NCSkillPlanSkill>(entityName: "SkillPlanSkill")
		request.predicate = NSPredicate(format: "skillPlan == %@", skillPlan)
		request.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: skillPlan.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)

		super.init(resultsController: results, sectionNode: nil, objectNode: NCSkillPlanSkillRow.self)
	}
	
	override func loadChildren() {
		super.loadChildren()
		updateChildren()
	}
	
	override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		super.controller(controller, didChange: anObject, at: indexPath, for: type, newIndexPath: newIndexPath)
		guard let parent = parent as? NCSkillPlanRow else {return}
		
		let trainingQueue = parent.trainingQueue
		
		switch type {
		case .insert:
			let item = anObject as! NCSkillPlanSkill
			let invTypes = NCDatabase.sharedDatabase?.invTypes
			if let type = invTypes?[Int(item.typeID)] {
				trainingQueue.add(skill: type, level: Int(item.level))
			}
		case .delete:
			let item = anObject as! NCSkillPlanSkill
			let typeID = Int(item.typeID)
			let level = Int(item.level)
			if let i = trainingQueue.skills.index(where: {return $0.skill.typeID == typeID && $0.level == level}) {
				trainingQueue.skills.remove(at: i)
			}
		default:
			break
		}
	}
	
	override func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		treeController?.beginUpdates()
		super.controllerWillChangeContent(controller)
	}
	
	override func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		super.controllerDidChangeContent(controller)
		updateChildren()
		if let parent = parent as? NCSkillPlanRow {
			parent.trainingTime = nil
			treeController?.reloadCells(for: [parent], with: .none)
		}

		treeController?.endUpdates()
	}
	
	private func updateChildren() {
		guard let parent = parent as? NCSkillPlanRow else {return}
		let character = parent.character
		let trainingQueue = parent.trainingQueue
		
		var skills: [Int: [Int:NCTrainingSkill]] = [:]
		
		trainingQueue.skills.forEach {
			_ = (skills[$0.skill.typeID]?[$0.level] = $0) ?? (skills[$0.skill.typeID] = [$0.level: $0])
		}
		
		var missing = [NCSkillPlanSkill]()
		children.forEach {
			guard let row = $0 as? NCSkillPlanSkillRow else {return}
			if let skill = skills[Int(row.object.typeID)]?[Int(row.object.level)] {
				row.skill = skill
				row.character = character
			}
			else {
				missing.append(row.object)
			}
		}
		if !missing.isEmpty {
			missing.forEach {
				$0.managedObjectContext?.delete($0)
			}
			if resultsController.managedObjectContext.hasChanges {
				try? resultsController.managedObjectContext.save()
			}
		}
		
	}
}

fileprivate class NCSkillPlanRow: NCFetchedResultsObjectNode<NCSkillPlan> {
	
	required init(object: NCSkillPlan) {
		super.init(object: object)
		cellIdentifier = Prototype.NCActionHeaderTableViewCell.default.reuseIdentifier
		isExpandable = true
		isExpanded = object.active
	}
	
	lazy var character: NCCharacter = {
		return (self.parent as? NCSkillPlansSection)?.character ?? NCCharacter()
	}()
	
	fileprivate var trainingTime: String?
	
	var title: String {
		if trainingTime == nil {
			trainingTime = NCTimeIntervalFormatter.localizedString(from: trainingQueue.trainingTime(characterAttributes: character.attributes), precision: .seconds)
		}
		
		var title = ""
		if let name = object.name?.uppercased() {
			title = "\(name): "
		}
		let skils = skillPlanSkills.resultsController.fetchedObjects
		let s = skils?.isEmpty == false ? String(format: NSLocalizedString("%@ (%d skills)", comment: ""), trainingTime!, skils!.count)
			: NSLocalizedString("Empty", comment: "")
			
		return title + s
	}
	
//	var handler: NCActionHandler?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCActionHeaderTableViewCell else {return}
		cell.titleLabel?.text = title
		cell.titleLabel?.textColor = object.active ? .caption : .lightText
		cell.actionHandler = NCActionHandler(cell.button!, for: .touchUpInside) { [weak self] _ in
			guard let strongSelf = self else {return}
			guard let controller = strongSelf.treeController else {return}
			controller.delegate?.treeController?(controller, accessoryButtonTappedWithNode: strongSelf)
		}
	}
	
	lazy var skillPlanSkills: NCSKillPlanSkillsNode = {
		let node = NCSKillPlanSkillsNode(skillPlan: self.object, character: self.character)
		try? node.resultsController.performFetch()
		return node
	}()
	
	lazy var trainingQueue: NCTrainingQueue = {
		let trainingQueue = NCTrainingQueue(character: self.character)
		let character = self.character
		
		let invTypes = NCDatabase.sharedDatabase?.invTypes
		
		self.skillPlanSkills.resultsController.fetchedObjects?.forEach { item in
			guard let type = invTypes?[Int(item.typeID)] else {return}
			let level = Int(item.level)
			guard character.skills[Int(item.typeID)]?.level ?? 0 < level else {return}
//			let skill = NCTrainingSkill(type: type, skill: character.skills[Int(item.typeID)], level: Int(item.level))
			guard let skill = NCTrainingSkill(type: type, skill: character.skills[Int(item.typeID)], level: level, trainedLevel: level-1) else {return}
			trainingQueue.skills.append(skill)
		}
		return trainingQueue
	}()
	
	override func loadChildren() {
		let node = skillPlanSkills

		defer {
			children = [node]
			super.loadChildren()
		}
	}
}

fileprivate class NCSkillPlansSection: FetchedResultsNode<NCSkillPlan> {
	let character: NCCharacter
	let account: NCAccount
	
	init(account: NCAccount, character: NCCharacter) {
		self.account = account
		self.character = character

		let request = NSFetchRequest<NCSkillPlan>(entityName: "SkillPlan")
		request.predicate = NSPredicate(format: "account == %@", account)
		request.sortDescriptors = [NSSortDescriptor(key: "active", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: account.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		super.init(resultsController: results, sectionNode: nil, objectNode: NCSkillPlanRow.self)
		cellIdentifier = Prototype.NCActionHeaderTableViewCell.default.reuseIdentifier
		isExpandable = true
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCActionHeaderTableViewCell else {return}
		cell.titleLabel?.text = NSLocalizedString("Skill Plans", comment: "").uppercased()
		cell.titleLabel?.textColor = .lightText
		
		cell.actionHandler = NCActionHandler(cell.button!, for: .touchUpInside) { [weak self] _ in
			guard let strongSelf = self else {return}
			guard let treeController = strongSelf.treeController else {return}
			treeController.delegate?.treeController?(treeController, accessoryButtonTappedWithNode: strongSelf)
		}

	}

}

fileprivate class NCOptimalCharacterAttributesSection: DefaultTreeSection {
	let account: NCAccount
	let character: NCCharacter
	
	var skillPlanObserver: NCManagedObjectObserver?
	var skillPlan: NCSkillPlan? {
		didSet {
			guard skillPlan != oldValue else {return}
			
			skillPlanObserver = nil
			guard let skillPlan = skillPlan else {return}
			skillPlanObserver = NCManagedObjectObserver(managedObject: skillPlan) { [weak self] (_,_) in
				self?.reload()
			}
		}
	}
	
	init(account: NCAccount, character: NCCharacter) {
		self.account = account
		self.character = character
//		self.skillPlan = account.activeSkillPlan
		super.init(nodeIdentifier: "OptimalCharacterAttributes", title: NSLocalizedString("Attributes (current/optimal)", comment: "").uppercased(),children: nil)
		reload()
	}
	
	func reload() {
		skillPlan = account.activeSkillPlan
		guard let objectID = skillPlan?.objectID else {return}

		let character = self.character

		NCStorage.sharedStorage?.performBackgroundTask { managedObjectContext in
			guard let skillPlan = (try? managedObjectContext.existingObject(with: objectID)) as? NCSkillPlan else {return}
			
			let request = NSFetchRequest<NCSkillPlanSkill>(entityName: "SkillPlanSkill")
			request.predicate = NSPredicate(format: "skillPlan == %@", skillPlan)
			request.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: skillPlan.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
			try? results.performFetch()
			
			let trainingQueue = NCTrainingQueue(character: character)
			
			NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext in
				let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
				
				results.fetchedObjects?.forEach { item in
					guard let type = invTypes[Int(item.typeID)] else {return}
					let level = Int(item.level)
					guard character.skills[Int(item.typeID)]?.level ?? 0 < level else {return}
					guard let skill = NCTrainingSkill(type: type, skill: character.skills[Int(item.typeID)], level: level, trainedLevel: level-1) else {return}
					trainingQueue.skills.append(skill)
				}
				
				character.skillQueue.forEach { item in
					guard let type = invTypes[item.skillID] else {return}
					let level = item.finishedLevel
					trainingQueue.add(skill: type, level: level)
				}
				
				let optimal = NCCharacterAttributes.optimal(for: trainingQueue)
				optimal?.augmentations = character.attributes.augmentations

				let current = character.attributes

				let t0 = trainingQueue.trainingTime(characterAttributes: current)
				let t1 = optimal != nil ? trainingQueue.trainingTime(characterAttributes: optimal!) : t0
				
				DispatchQueue.main.async {
					let optimal = optimal ?? current
					var rows = [("Intelligence", NSLocalizedString("Intelligence", comment: ""), #imageLiteral(resourceName: "intelligence"), current.intelligence, optimal.intelligence),
					            ("Memory", NSLocalizedString("Memory", comment: ""), #imageLiteral(resourceName: "memory"), current.memory, optimal.memory),
					            ("Perception", NSLocalizedString("Perception", comment: ""), #imageLiteral(resourceName: "perception"), current.perception, optimal.perception),
					            ("Willpower", NSLocalizedString("Willpower", comment: ""), #imageLiteral(resourceName: "willpower"), current.willpower, optimal.willpower),
					            ("Charisma", NSLocalizedString("Charisma", comment: ""), #imageLiteral(resourceName: "charisma"), current.charisma, optimal.charisma)].map { i -> TreeRow in
									return DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: i.0, image: i.2, title: i.1.uppercased(), subtitle: "\(i.3)/\(i.4) \(NSLocalizedString("points", comment: ""))")
					}
					let dt = t0 - t1
					if dt > 0 {
						rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, nodeIdentifier: "Better", title: String(format: NSLocalizedString("%@ better than current", comment: ""), NCTimeIntervalFormatter.localizedString(from: dt, precision: .seconds))))
					}
					self.children = rows
				}
			}
		}
		

	}
}

class NCSkillQueueViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		
		tableView.register([
			Prototype.NCHeaderTableViewCell.default,
			Prototype.NCActionHeaderTableViewCell.default,
			Prototype.NCActionTableViewCell.default,
			Prototype.NCDefaultTableViewCell.default,
			Prototype.NCSkillTableViewCell.default,
			Prototype.NCDefaultTableViewCell.attribute,
			Prototype.NCDefaultTableViewCell.placeholder
			]
		)
	}
	
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if let context = NCStorage.sharedStorage?.viewContext, context.hasChanges {
			try? context.save()
		}
	}

	
	@IBAction func onAddSkillPlan(_ sender: Any) {
		guard let account = NCAccount.current, let managedObjectContext = account.managedObjectContext else {return}
		let skillPlan = NCSkillPlan(entity: NSEntityDescription.entity(forEntityName: "SkillPlan", in: managedObjectContext)!, insertInto: managedObjectContext)
		skillPlan.name = NSLocalizedString("Unnamed", comment: "")
		skillPlan.account = account
		account.activeSkillPlan?.active = false
		skillPlan.active = true
		if account.managedObjectContext?.hasChanges == true {
			try? account.managedObjectContext?.save()
		}
	}
	
	@IBAction func onSkillPlanActions(_ sender: UIButton) {
		guard let cell = sender.ancestor(of: NCHeaderTableViewCell.self) else {return}
		guard let skillPlan = cell.object as? NCSkillPlan else {return}
		
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		if skillPlan.account?.skillPlans?.count ?? 0 > 1 {
			controller.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { (action) in
				guard let context = skillPlan.managedObjectContext else {return}
				if skillPlan.active {
					if let item = (skillPlan.account?.skillPlans?.sortedArray(using: [NSSortDescriptor(key: "name", ascending: true)]) as? [NCSkillPlan])?.first(where: { $0 !== skillPlan }) {
						item.active = true
					}
				}
				
				context.delete(skillPlan)
				if context.hasChanges == true {
					try? context.save()
				}
			}))
		}
		
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
			let controller = UIAlertController(title: NSLocalizedString("Rename", comment: ""), message: nil, preferredStyle: .alert)
			
			var textField: UITextField?
			
			controller.addTextField(configurationHandler: {
				textField = $0
				textField?.text = skillPlan.name
				textField?.clearButtonMode = .always
			})
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
				if textField?.text?.count ?? 0 > 0 && skillPlan.name != textField?.text {
					skillPlan.name = textField?.text
					if skillPlan.managedObjectContext?.hasChanges == true {
						try? skillPlan.managedObjectContext?.save()
					}
				}
			}))
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
			
			self.present(controller, animated: true, completion: nil)
		}))
		
		if !skillPlan.active {
			controller.addAction(UIAlertAction(title: NSLocalizedString("Activate", comment: ""), style: .default, handler: { (action) in
				skillPlan.account?.activeSkillPlan?.active = false
				skillPlan.active = true
				if skillPlan.managedObjectContext?.hasChanges == true {
					try? skillPlan.managedObjectContext?.save()
				}
			}))
		}
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		controller.popoverPresentationController?.sourceView = sender
		controller.popoverPresentationController?.sourceRect = sender.bounds
		self.present(controller, animated: true, completion: nil)
	}
	
	//MARK: TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		switch node {
		case is NCSkillPlansSection:
			guard let account = NCAccount.current, let managedObjectContext = account.managedObjectContext else {return}

			let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			controller.addAction(UIAlertAction(title: NSLocalizedString("Add Skill Plan", comment: ""), style: .default, handler: { _ in
				account.skillPlans?.forEach {
					($0 as? NCSkillPlan)?.active = false
				}

				let skillPlan = NCSkillPlan(entity: NSEntityDescription.entity(forEntityName: "SkillPlan", in: managedObjectContext)!, insertInto: managedObjectContext)
				skillPlan.name = NSLocalizedString("Unnamed", comment: "")
				skillPlan.account = account
				skillPlan.active = true
				if account.managedObjectContext?.hasChanges == true {
					try? account.managedObjectContext?.save()
				}
			}))
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
			self.present(controller, animated: true, completion: nil)
			let sender = treeController.cell(for: node)
			controller.popoverPresentationController?.sourceView = sender
			controller.popoverPresentationController?.sourceRect = sender?.bounds ?? .zero

		case let row as NCSkillPlanRow:
			let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			let skillPlan = row.object

			if (skillPlan.skills?.count ?? 0) > 0 {
				controller.addAction(UIAlertAction(title: NSLocalizedString("Clear", comment: ""), style: .default, handler: { _ in
					(skillPlan.skills?.allObjects as? [NCSkillPlanSkill])?.forEach { skill in
						skill.managedObjectContext?.delete(skill)
						skill.skillPlan = nil
					}
					
					if skillPlan.managedObjectContext?.hasChanges == true {
						try? skillPlan.managedObjectContext?.save()
					}
				}))
			}
			
			if !skillPlan.active {
				controller.addAction(UIAlertAction(title: NSLocalizedString("Make Active", comment: ""), style: .default, handler: { _ in
					skillPlan.account?.skillPlans?.forEach {
						($0 as? NCSkillPlan)?.active = false
					}
					skillPlan.active = true
					if skillPlan.managedObjectContext?.hasChanges == true {
						try? skillPlan.managedObjectContext?.save()
					}
				}))
			}
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
				let controller = UIAlertController(title: NSLocalizedString("Rename", comment: ""), message: nil, preferredStyle: .alert)
				
				var textField: UITextField?
				
				controller.addTextField(configurationHandler: {
					textField = $0
					textField?.text = skillPlan.name
					textField?.clearButtonMode = .always
				})
				
				controller.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
					if textField?.text?.count ?? 0 > 0 && skillPlan.name != textField?.text {
						skillPlan.name = textField?.text
						if skillPlan.managedObjectContext?.hasChanges == true {
							try? skillPlan.managedObjectContext?.save()
						}
					}
				}))
				
				controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
				
				self.present(controller, animated: true, completion: nil)
			}))
			
			if (skillPlan.account?.skillPlans?.count ?? 0) > 1 {
				controller.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { _ in
					
					if skillPlan.active {
						if let item = (skillPlan.account?.skillPlans?.sortedArray(using: [NSSortDescriptor(key: "name", ascending: true)]) as? [NCSkillPlan])?.first(where: { $0 !== skillPlan }) {
							item.active = true
						}
					}
					skillPlan.managedObjectContext?.delete(skillPlan)
					if skillPlan.managedObjectContext?.hasChanges == true {
						try? skillPlan.managedObjectContext?.save()
					}
				}))
			}
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
			self.present(controller, animated: true, completion: nil)
			let sender = treeController.cell(for: node)
			controller.popoverPresentationController?.sourceView = sender
			controller.popoverPresentationController?.sourceRect = sender?.bounds ?? .zero

		default:
			break
		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		switch node {
		case let item as NCSkillPlanRow:
			let skillPlan = item.object
			guard skillPlan.account?.skillPlans?.count ?? 0 > 1 else {return nil}
			
			let remove = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (_, _) in
				let context = skillPlan.managedObjectContext
				if skillPlan.active {
					if let item = (skillPlan.account?.skillPlans?.sortedArray(using: [NSSortDescriptor(key: "name", ascending: true)]) as? [NCSkillPlan])?.first(where: { $0 !== skillPlan }) {
						item.active = true
					}
				}

				context?.delete(skillPlan)
				if context?.hasChanges == true {
					try? context?.save()
				}
			}
			return [remove]
		case let item as NCSkillPlanSkillRow:
			let skill = item.object
			
			let remove = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (_, _) in
				guard let skillPlan = skill.skillPlan else {return}
				guard let managedObjectContext = skillPlan.managedObjectContext else {return}
				let request = NSFetchRequest<NCSkillPlanSkill>(entityName: "SkillPlanSkill")
				request.predicate = NSPredicate(format: "skillPlan == %@ AND typeID == %d AND level >= %d", skillPlan, skill.typeID, skill.level)
				
				for skill in (try? managedObjectContext.fetch(request)) ?? [] {
					managedObjectContext.delete(skill)
				}
				
				if managedObjectContext.hasChanges == true {
					try? managedObjectContext.save()
				}
			}
			return [remove]
		default:
			return nil
		}
	}
	
    //MARK: - NCRefreshable
	
	var characterObserver: NotificationObserver?
	
	private var character: NCCharacter? {
		didSet {
			characterObserver = nil
			if let character = character {
				characterObserver = NotificationCenter.default.addNotificationObserver(forName: .NCCharacterChanged, object: character, queue: nil) { [weak self] _ in
					self?.updateContent {
					}
				}
			}
		}
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
        if let account = NCAccount.current {
            NCCharacter.load(account: account) { result in
                switch result {
                case let .success(character):
                    self.character = character

					completionHandler([])

                case let .failure(error):
                    if self.treeController?.content == nil {
                        self.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
                    }
					completionHandler([])

                }
            }
        }
        else {
            completionHandler([])
        }
    }
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		guard let account = NCAccount.current, let character = character else {
			completionHandler()
			return
		}
		let skillBrowser = TreeSection(prototype: nil)
		skillBrowser.children = [NCActionRow(title: NSLocalizedString("SKILL BROWSER", comment: ""),
		                                     route: Router.Character.Skills())]
		self.skillBrowser = skillBrowser
		
		var sections: [TreeNode] = []
		
		if traitCollection.horizontalSizeClass != .regular {
			sections.append(skillBrowser)
		}

		
		let attributes = NCOptimalCharacterAttributesSection(account: account, character: character)
		
		attributes.isExpanded = false
		sections.append(attributes)
		
		let skillQueue = NCSkillQueueSection(character: character)
		sections.append(skillQueue)
		sections.append(NCSkillPlansSection(account: account, character: character))
		
		if treeController?.content == nil {
			treeController?.content = RootNode(sections)
		}
		else {
			treeController?.content?.children = sections
		}
		completionHandler()
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		guard previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass else {return}

		NSObject.cancelPreviousPerformRequests(withTarget: self)
		perform(#selector(updateTraits), with: nil, afterDelay: 0)
	}
	
	private var skillBrowser: TreeSection?
	
	@objc private func updateTraits() {
		guard let skillBrowser = skillBrowser else {return}
		if traitCollection.horizontalSizeClass == .regular {
			guard treeController?.content?.children.first === skillBrowser else {return}
			treeController?.content?.children.removeFirst()
		}
		else {
			guard treeController?.content?.children.first !== skillBrowser else {return}
			treeController?.content?.children.insert(skillBrowser, at: 0)
		}
	}
	
}
