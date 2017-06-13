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
	
	override var hashValue: Int {
		return skill.hashValue
	}
	
	static func ==(lhs: NCSkillQueueRow, rhs: NCSkillQueueRow) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}



fileprivate class NCSkillPlanSkillRow: FetchedResultsObjectNode<NCSkillPlanSkill> {
	var skill: NCTrainingSkill?
	var character: NCCharacter?
	
	required init(object: NCSkillPlanSkill) {
		super.init(object: object)
		cellIdentifier = Prototype.NCSkillTableViewCell.default.reuseIdentifier
	}
	
//	init(skill: NCTrainingSkill?, character: NCCharacter, object: NCSkillPlanSkill) {
//		self.skill = skill
//		self.character = character
//		super.init(prototype: Prototype.NCSkillTableViewCell.default, route: Router.Database.TypeInfo(Int(object.typeID)), object: object)
//	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCSkillTableViewCell else {return}
		guard let character = character else {return}
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
				return NCSkillQueueRow(skill: skill)
			}
		}

		let children = rows(character.skillQueue)
		
		func title(_ skillQueue: [ESI.Skills.SkillQueueItem], count: Int) -> String {
			if let lastSkill = skillQueue.last, let endDate = lastSkill.finishDate, endDate > Date() {
				return String(format: NSLocalizedString("SKILL QUEUE: %@ (%d skills)", comment: ""),
				                               NCTimeIntervalFormatter.localizedString(from: max(0, endDate.timeIntervalSinceNow), precision: .minutes), count)
			}
			else {
				return NSLocalizedString("No skills in training", comment: "")
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
/*
fileprivate class NCSkillPlanSection: FetchedResultsSectionNode<NCSkillPlan> {
	let results: NSFetchedResultsController<NCSkillPlan>
	let character: NCCharacter
	let trainingQueue: NCTrainingQueue
	
	var observer: NCManagedObjectObserver?
	
	required init(section: NSFetchedResultsSectionInfo, objectNode: FetchedResultsObjectNode<NCSkillPlanSkill>.Type) {
		super.init(section: section, objectNode: objectNode)
		cellIdentifier = Prototype.NCDefaultTableViewCell.default.reuseIdentifier
	}
	
	/*init(skillPlan: NCSkillPlan, character: NCCharacter) {
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
	}*/
	
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
*/

fileprivate class NCSKillPlanSkillsNode: FetchedResultsNode<NCSkillPlanSkill> {
	
	init(skillPlan: NCSkillPlan, character: NCCharacter) {
		let request = NSFetchRequest<NCSkillPlanSkill>(entityName: "SkillPlanSkill")
		request.predicate = NSPredicate(format: "skillPlan == %@", skillPlan)
		request.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: skillPlan.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)

		super.init(resultsController: results, sectionNode: nil, objectNode: NCSkillPlanSkillRow.self)
	}
}

fileprivate class NCSkillPlanRow: FetchedResultsObjectNode<NCSkillPlan> {
	
	required init(object: NCSkillPlan) {
		super.init(object: object)
		cellIdentifier = Prototype.NCHeaderTableViewCell.default.reuseIdentifier
	}
	
	var character: NCCharacter {
		return NCCharacter()
	}
	
	var _title: NSAttributedString?
	
	var title: NSAttributedString? {
		if _title == nil {
			let title = NSMutableAttributedString()
			if let name = object.name?.uppercased() {
				title.append(NSAttributedString(string: "\(name): ", attributes: object.active ? [NSForegroundColorAttributeName: UIColor.caption] : nil))
			}
			let skils = skillPlanSkills.resultsController.fetchedObjects
			let s = skils?.isEmpty ?? true ? NSLocalizedString("Empty", comment: "") :
				String(format: NSLocalizedString("%@ (%d skills)", comment: ""), NCTimeIntervalFormatter.localizedString(from: trainingQueue.trainingTime(characterAttributes: character.attributes), precision: .seconds), skils?.count ?? 0)
			title.append(NSAttributedString(string: s))
			_title = title
		}
		return _title
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.titleLabel?.attributedText = title
	}
	
	lazy var skillPlanSkills: NCSKillPlanSkillsNode = {
		let node = NCSKillPlanSkillsNode(skillPlan: self.object, character: self.character)
		return node
	}()
	
	lazy var trainingQueue: NCTrainingQueue = {
		let trainingQueue = NCTrainingQueue(character: self.character)
		let character = self.character
		
		let invTypes = NCDatabase.sharedDatabase?.invTypes
		
		
		self.skillPlanSkills.resultsController.fetchedObjects?.forEach { item in
			let type = invTypes?[Int(item.typeID)]
			let skill = NCTrainingSkill(type: type, skill: character.skills[Int(item.typeID)], level: Int(item.level))
			if let skill = skill, let type = type {
				trainingQueue.add(skill: type, level: Int(skill.level))
			}
		}
		return trainingQueue
	}()
	
	override func loadChildren() {
		let node = skillPlanSkills

		defer {
			children = [node]
			super.loadChildren()
		}
		
		let character = self.character
		let trainingQueue = self.trainingQueue
		
		guard trainingQueue.skills.count == node.children.count else {return}
		
		var skills: [Int: [Int:NCTrainingSkill]] = [:]
		
		trainingQueue.skills.forEach {
			_ = (skills[$0.skill.typeID]?[$0.level] = $0) ?? (skills[$0.skill.typeID] = [$0.level: $0])
		}
		
		node.children.forEach {
			guard let row = $0 as? NCSkillPlanSkillRow else {return}
			row.skill = skills[Int(row.object.typeID)]?[Int(row.object.level)]
			row.character = character
			
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
		let expr = (request.predicate as! NSComparisonPredicate).rightExpression
		let v = expr.constantValue
		try? results.performFetch()
		super.init(resultsController: results, sectionNode: nil, objectNode: NCSkillPlanRow.self)
		cellIdentifier = Prototype.NCActionHeaderTableViewCell.default.reuseIdentifier
	}
	
	private var buttonHandler: NCActionHandler?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCActionHeaderTableViewCell else {return}
		cell.titleLabel?.text = NSLocalizedString("Skill Plans", comment: "").uppercased()
		
		buttonHandler = NCActionHandler(cell.button!, for: .touchUpInside) { [weak self] _ in
			guard let strongSelf = self else {return}
			guard let treeController = strongSelf.treeController else {return}
			treeController.delegate?.treeController?(treeController, accessoryButtonTappedWithNode: strongSelf)
		}

	}

}

class NCSkillQueueViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	@IBOutlet weak var treeController: TreeController!
	var character: NCCharacter?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.delegate = treeController
		tableView.dataSource = treeController
		
		tableView.register([
			Prototype.NCHeaderTableViewCell.default,
			Prototype.NCActionHeaderTableViewCell.default,
			Prototype.NCActionTableViewCell.default,
			Prototype.NCDefaultTableViewCell.default,
			]
		)
		
        registerRefreshable()
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
				if textField?.text?.characters.count ?? 0 > 0 && skillPlan.name != textField?.text {
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
	
	//MARK: TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let route = (node as? TreeNodeRoutable)?.route {
			route.perform(source: self, view: treeController.cell(for: node))
		}
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		switch node {
		case is NCSkillPlansSection:
			guard let account = NCAccount.current, let managedObjectContext = account.managedObjectContext else {return}

			let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			controller.addAction(UIAlertAction(title: NSLocalizedString("Add Skill Plan", comment: ""), style: .default, handler: { _ in
				if account.skillPlans?.count ?? 0 > 0 {
					account.activeSkillPlan?.active = false
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
	
//	func treeController(_ treeController: NCTreeController, canEditChild child:Int, ofItem item: AnyObject?) -> Bool {
//		if item is NCSkillPlanSection || (item as? NCTreeSection)?.children?[child] is NCSkillPlanSection {
//			return true
//		}
//		else {
//			return false
//		}
//	}
	
	func treeController(_ treeController: NCTreeController, didSelectCell cell: UITableViewCell, withItem item: AnyObject) -> Void {
		switch (item as? NCDefaultTreeRow)?.segue {
		case "NCSkillsViewController"?:
			self.performSegue(withIdentifier: "NCSkillsViewController", sender: cell)
		default:
			break
		}
	}
	
/*	func treeController(_ treeController: NCTreeController, isItemExpanded item: AnyObject) -> Bool {
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
	}*/

    //MARK: - NCRefreshable
	
    func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
        if let account = NCAccount.current {
            let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
            progress.progress.becomeCurrent(withPendingUnitCount: 1)
            
            NCCharacter.load(account: account) { result in
                switch result {
                case let .success(character):
                    self.character = character
					let skillBrowser = NCActionRow(title: NSLocalizedString("SKILL BROWSER", comment: ""),
					                               route: nil)
                    var sections: [TreeNode] = [skillBrowser]
                    
                    let skillQueue = NCSkillQueueSection(character: character)
                    sections.append(skillQueue)
                    sections.append(NCSkillPlansSection(account: account, character: character))
					
					if self.treeController.content == nil {
						let root = TreeNode()
						root.children = sections
						self.treeController.content = root
					}
					else {
						self.treeController.content?.children = sections
					}
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
    
	//MARK: Private
	
	@objc private func refresh() {
		reload(cachePolicy: .reloadIgnoringLocalCacheData) {
			self.refreshControl?.endRefreshing()
		}
	}
}
