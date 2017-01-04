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

fileprivate class NCSkillQueueRow: NCTreeRow {
	let skill: NCSkill
	init(skill: NCSkill) {
		self.skill = skill
		super.init(cellIdentifier: "NCSkillTableViewCell")
	}
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCSkillTableViewCell {
			cell.iconView?.image = nil
			cell.titleLabel?.text = "\(skill.typeName) (x\(skill.rank))"
			cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:min(1 + (skill.level ?? 0), 5))
			cell.progressView?.progress = skill.trainingProgress
			
			let a = NCUnitFormatter.localizedString(from: Double(skill.skillPoints), unit: .none, style: .full)
			let b = NCUnitFormatter.localizedString(from: Double(skill.skillPoints(at: 1 + (skill.level ?? 0))), unit: .skillPoints, style: .full)
			cell.spLabel?.text = "\(a) / \(b)"
			if let from = skill.trainingStartDate, let to = skill.trainingEndDate {
				cell.trainingTimeLabel?.text = NCTimeIntervalFormatter.localizedString(from: max(to.timeIntervalSince(from), 0), precision: .minutes)
			}
			else {
				cell.trainingTimeLabel?.text = nil
			}
		}
	}
	
	override var hashValue: Int {
		return skill.hashValue
	}
	
	static func ==(lhs: NCSkillQueueRow, rhs: NCSkillQueueRow) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}

fileprivate class NCSkillPlanRow: NCTreeRow {
	let skill: NCTrainingSkill?
	let character: NCCharacter
	init(skill: NCTrainingSkill?, character: NCCharacter, object: NCSkillPlanSkill) {
		self.skill = skill
		self.character = character
		super.init(cellIdentifier: "NCSkillTableViewCell", object: object)
	}
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCSkillTableViewCell {
			if let skill = skill {
				cell.titleLabel?.text = "\(skill.skill.typeName) (x\(skill.skill.rank))"
				cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:min(skill.level, 5))
				let a = NCUnitFormatter.localizedString(from: Double(skill.skill.skillPoints), unit: .none, style: .full)
				let b = NCUnitFormatter.localizedString(from: Double(skill.skill.skillPoints(at: skill.level)), unit: .skillPoints, style: .full)
				cell.spLabel?.text = "\(a) / \(b)"
				let t = skill.trainingTime(characterAttributes: character.attributes)
				cell.trainingTimeLabel?.text = NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes)
			}
			else {
				cell.titleLabel?.text =	NSLocalizedString("Unknown Type", comment: "")
				cell.levelLabel?.text = nil
				cell.trainingTimeLabel?.text = " "
				cell.spLabel?.text = " "
			}
			cell.iconView?.image = #imageLiteral(resourceName: "skillRequirementQueued")
			
			cell.progressView?.progress = 0
		}
	}
	
	override var hashValue: Int {
		return skill?.hashValue ?? 0
	}
	
	static func ==(lhs: NCSkillPlanRow, rhs: NCSkillPlanRow) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}

fileprivate class NCSkillQueueSection: NCTreeSection {
	var observer: NSObjectProtocol?
	let character: NCCharacter
	
	init(character: NCCharacter) {
		self.character = character
		
		let invTypes = NCDatabase.sharedDatabase?.invTypes
		func rows(_ skillQueue: [ESSkillQueueItem]) -> [NCSkillQueueRow] {
			let date = Date()
			return skillQueue.flatMap { (item) in
				guard let finishDate = item.finishDate, finishDate > date else {return nil}
				guard let type = invTypes?[item.skillID] else {return nil}
				guard let skill = NCSkill(type: type, skill: item) else {return nil}
				return NCSkillQueueRow(skill: skill)
			}
		}

		let children = rows(character.skillQueue)
		
		func title(_ skillQueue: [ESSkillQueueItem]) -> String {
			if let lastSkill = skillQueue.last, let endDate = lastSkill.finishDate, endDate > Date() {
				return String(format: NSLocalizedString("SKILL QUEUE: %@ (%d skills)", comment: ""),
				                               NCTimeIntervalFormatter.localizedString(from: max(0, endDate.timeIntervalSinceNow), precision: .minutes), skillQueue.count)
			}
			else {
				return NSLocalizedString("No skills in training", comment: "")
			}
		}
		

		
		super.init(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "SkillQueue", title: title(character.skillQueue), children: children)

		observer = NotificationCenter.default.addObserver(forName: .NCCharacterChanged, object: character, queue: .main) {[weak self] note in
			guard let strongSelf = self else {return}
			
			let to = rows(character.skillQueue)
			
			let from = strongSelf.mutableArrayValue(forKey: "children")
			(from.copy() as! [NCSkillQueueRow]).transition(to: to, handler: { (old, new, type) in
				switch type {
				case .insert:
					from.insert(to[new!], at: new!)
				case .delete:
					from.removeObject(at: old!)
				case .move:
					from.removeObject(at: old!)
					from.insert(to[new!], at: new!)
				case .update:
					break
				}
			})
			self?.title = title(character.skillQueue)
		}

	}
}

fileprivate class NCSkillPlanSection: NCTreeSection, NSFetchedResultsControllerDelegate {
	let results: NSFetchedResultsController<NCSkillPlanSkill>
	let character: NCCharacter
	let trainingQueue: NCTrainingQueue
	
	var observer: NCManagedObjectObserver?

	init(skillPlan: NCSkillPlan, character: NCCharacter) {
		self.character = character
		let request = NSFetchRequest<NCSkillPlanSkill>(entityName: "SkillPlanSkill")
		request.predicate = NSPredicate(format: "skillPlan == %@", skillPlan)
		request.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
		results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: skillPlan.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		try? results.performFetch()

		let trainingQueue = NCTrainingQueue(character: character)
		
		let invTypes = NCDatabase.sharedDatabase?.invTypes
		let children = results.fetchedObjects?.map { (item) -> NCSkillPlanRow in
			let type = invTypes?[Int(item.typeID)]
			let skill = NCTrainingSkill(type: type, skill: character.skills[Int(item.typeID)], level: Int(item.level))
			if let skill = skill, let type = type {
				trainingQueue.add(skill: type, level: Int(skill.level))
			}
			return NCSkillPlanRow(skill: skill, character: character, object: item)
		}
		
		self.trainingQueue = trainingQueue
		super.init(cellIdentifier: "NCSkillPlanHeaderTableViewCell", nodeIdentifier: "SkillPlan", children: children ?? [], object: skillPlan)
		updateTitle()
		results.delegate = self
		
		observer = NCManagedObjectObserver(managedObject: skillPlan, handler: {[weak self] (updated, deleted) in
			if updated?.contains(skillPlan) == true {
				self?.updateTitle()
			}
		})
	}
	
	func updateTitle() {
		let skillPlan = object as? NCSkillPlan
		
		let title = NSMutableAttributedString()
		if let name = skillPlan?.name?.uppercased() {
			title.append(NSAttributedString(string: "\(name): ", attributes: skillPlan?.active == true ? [NSForegroundColorAttributeName: UIColor.caption] : nil))
		}
		let s = children?.count == 0 ? NSLocalizedString("Empty", comment: "") :
			String(format: NSLocalizedString("%@ (%d skills)", comment: ""), NCTimeIntervalFormatter.localizedString(from: trainingQueue.trainingTime(characterAttributes: character.attributes), precision: .seconds), children?.count ?? 0)
		title.append(NSAttributedString(string: s))
		self.attributedTitle = title
	}
	
	//MARK: NSFetchedResultsControllerDelegate
	
	var insert: [(Int, NCSkillPlanRow)]?
	var delete: [Int]?
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		insert = []
		delete = []
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		delete?.sort(by: >)
		insert?.sort(by: { (a, b) -> Bool in
			a.0 < b.0
		})
		let array = self.mutableArrayValue(forKey: "children")
		for i in delete ?? [] {
			array.removeObject(at: i)
		}
		for (i, obj) in insert ?? [] {
			array.insert(obj, at: i)
		}
		insert = nil
		delete = nil
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			let item = anObject as! NCSkillPlanSkill
			let invTypes = NCDatabase.sharedDatabase?.invTypes
			let type = invTypes?[Int(item.typeID)]
			let skill = NCTrainingSkill(type: type, skill: character.skills[Int(item.typeID)], level: Int(item.level))

			if let skill = skill, let type = type {
				trainingQueue.add(skill: type, level: Int(skill.level))
			}

			insert?.append((newIndexPath!.row, NCSkillPlanRow(skill: skill, character: character, object: item)))
		case .delete:
			let item = anObject as! NCSkillPlanSkill
			let typeID = Int(item.typeID)
			let level = Int(item.level)
			if let skill = trainingQueue.skills.first(where: {return $0.skill.typeID == typeID && $0.level == level}) {
				trainingQueue.remove(skill: skill)
			}
			delete?.append(indexPath!.row)
		case .move:
			let obj = children?[indexPath!.row]
			delete?.append(indexPath!.row)
			insert?.append((newIndexPath!.row, obj as! NCSkillPlanRow))
		case .update:
			break
		}
	}
}

fileprivate class NCSkillPlansSection: NCTreeSection, NSFetchedResultsControllerDelegate {
	let character: NCCharacter
	let account: NCAccount
	let results: NSFetchedResultsController<NCSkillPlan>
	
	init(account: NCAccount, character: NCCharacter) {
		self.account = account
		self.character = character
		let request = NSFetchRequest<NCSkillPlan>(entityName: "SkillPlan")
		request.predicate = NSPredicate(format: "account == %@", account)
		request.sortDescriptors = [NSSortDescriptor(key: "active", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
		results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: account.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		try? results.performFetch()
		let children = results.fetchedObjects?.map {
			return NCSkillPlanSection(skillPlan: $0, character: character)
		}
		super.init(cellIdentifier: "NCSkillPlansHeaderTableViewCell", nodeIdentifier: "SkillPlans", title: NSLocalizedString("SKILL PLANS", comment: ""), children: children ?? [])
		results.delegate = self
	}
	
	//MARK: NSFetchedResultsControllerDelegate
	
	var insert: [(Int, NCSkillPlanSection)]?
	var delete: [Int]?
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		insert = []
		delete = []
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		delete?.sort(by: >)
		insert?.sort(by: { (a, b) -> Bool in
			a.0 < b.0
		})
		let array = self.mutableArrayValue(forKey: "children")
		for i in delete ?? [] {
			array.removeObject(at: i)
		}
		for (i, obj) in insert ?? [] {
			array.insert(obj, at: i)
		}
		insert = nil
		delete = nil
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			insert?.append((newIndexPath!.row, NCSkillPlanSection(skillPlan: anObject as! NCSkillPlan, character: character)))
		case .delete:
			delete?.append(indexPath!.row)
		case .move:
			let obj = children?[indexPath!.row]
			delete?.append(indexPath!.row)
			insert?.append((newIndexPath!.row, obj as! NCSkillPlanSection))
		case .update:
			break
		}
	}
}

class NCSkillQueueViewController: UITableViewController {
	@IBOutlet weak var treeController: NCTreeController!
	var character: NCCharacter?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		treeController.childrenKeyPath = "children"
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
	}
	
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController.content == nil {
			reload()
		}
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
				if textField?.text?.utf8.count ?? 0 > 0 && skillPlan.name != textField?.text {
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
		self.present(controller, animated: true, completion: nil)
	}
	
	//MARK: NCTreeControllerDelegate
	
	func treeController(_ treeController: NCTreeController, cellIdentifierForItem item: AnyObject) -> String {
		return (item as! NCTreeNode).cellIdentifier
	}
	
	func treeController(_ treeController: NCTreeController, configureCell cell: UITableViewCell, withItem item: AnyObject) {
		(item as! NCTreeNode).configure(cell: cell)
	}
	
	func treeController(_ treeController: NCTreeController, editActionsForChild child: Int, ofItem item: AnyObject?) -> [UITableViewRowAction]? {
		switch (item as? NCTreeNode)?.children?[child] {
		case let item as NCSkillPlanSection:
			guard let skillPlan = item.object as? NCSkillPlan else {return nil}
			guard skillPlan.account?.skillPlans?.count ?? 0 > 1 else {return nil}
			
			let remove = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (_, _) in
				let context = skillPlan.managedObjectContext
				context?.delete(skillPlan)
				if context?.hasChanges == true {
					try? context?.save()
				}
			}
			return [remove]
		case let item as NCSkillPlanRow:
			guard let skill = item.object as? NCSkillPlanSkill else {return nil}
			
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
	
	func treeController(_ treeController: NCTreeController, canEditChild child:Int, ofItem item: AnyObject?) -> Bool {
		if item is NCSkillPlanSection || (item as? NCTreeSection)?.children?[child] is NCSkillPlanSection {
			return true
		}
		else {
			return false
		}
	}
	
	func treeController(_ treeController: NCTreeController, didSelectCell cell: UITableViewCell, withItem item: AnyObject) -> Void {
		switch (item as? NCDefaultTreeRow)?.segue {
		case "NCSkillsViewController"?:
			self.performSegue(withIdentifier: "NCSkillsViewController", sender: cell)
		default:
			break
		}
	}
	
	func treeController(_ treeController: NCTreeController, isItemExpanded item: AnyObject) -> Bool {
		if let node = item as? NCSkillPlanSection {
			return (node.object as? NCSkillPlan)?.active == true
		}
		else {
			guard let node = (item as? NCTreeNode)?.nodeIdentifier else {return false}
			let setting = NCSetting.setting(key: "NCSkillQueueViewController.\(node)")
			return setting?.value as? Bool ?? true
		}
	}
	
	func treeController(_ treeController: NCTreeController, didExpandCell cell: UITableViewCell, withItem item: AnyObject) {
		guard let node = (item as? NCTreeNode)?.nodeIdentifier else {return}
		let setting = NCSetting.setting(key: "NCSkillQueueViewController.\(node)")
		setting?.value = true as NSNumber
	}
	
	func treeController(_ treeController: NCTreeController, didCollapseCell cell: UITableViewCell, withItem item: AnyObject) {
		guard let node = (item as? NCTreeNode)?.nodeIdentifier else {return}
		let setting = NCSetting.setting(key: "NCSkillQueueViewController.\(node)")
		setting?.value = false as NSNumber
	}

	
	//MARK: Private
	
	@objc private func refresh() {
		reload(cachePolicy: .reloadIgnoringLocalCacheData) {
			self.refreshControl?.endRefreshing()
		}
	}
	
	private func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		if let account = NCAccount.current {
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			progress.progress.becomeCurrent(withPendingUnitCount: 1)
			
			NCCharacter.load(account: account) { result in
				switch result {
				case let .success(character):
					self.character = character
					var content: [NCTreeNode] = [NCDefaultTreeRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "skills"), title: NSLocalizedString("SKILL BROWSER", comment: ""), accessoryType: .disclosureIndicator, segue: "NCSkillsViewController")]
					
					let skillQueue = NCSkillQueueSection(character: character)
					content.append(skillQueue)
					content.append(NCSkillPlansSection(account: account, character: character))

					self.treeController.content = content
					self.treeController.reloadData()
					
				case let .failure(error):
					if self.treeController.content == nil {
						self.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
					}
				}
				completionHandler?()
			}
			progress.progress.resignCurrent()
		}
		else {
			completionHandler?()
		}
	}

}
