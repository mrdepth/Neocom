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
	let skill: NCTrainingSkill
	let character: NCCharacter
	init(skill: NCTrainingSkill, character: NCCharacter) {
		self.skill = skill
		self.character = character
		super.init(cellIdentifier: "NCSkillTableViewCell")
	}
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCSkillTableViewCell {
			cell.titleLabel?.text = "\(skill.skill.typeName) (x\(skill.skill.rank))"
			cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:min(skill.level, 5))
			cell.progressView?.progress = 0
			
			let a = NCUnitFormatter.localizedString(from: Double(skill.skill.skillPoints), unit: .none, style: .full)
			let b = NCUnitFormatter.localizedString(from: Double(skill.skill.skillPoints(at: skill.level)), unit: .skillPoints, style: .full)
			cell.spLabel?.text = "\(a) / \(b)"
			let t = skill.trainingTime(characterAttributes: character.attributes)
			cell.trainingTimeLabel?.text = NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes)
		}
	}
	
	override var hashValue: Int {
		return skill.hashValue
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
		
		super.init(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "SkillQueue", children: children)

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
		}

	}
	
	
	override func configure(cell: UITableViewCell) {
		let date = Date()
		let cell = cell as! NCHeaderTableViewCell
		let skillQueue = character.skillQueue.filter({return $0.finishDate != nil && $0.finishDate! > date})
		if let lastSkill = skillQueue.last, let endDate = lastSkill.finishDate {
			cell.titleLabel?.text = String(format: NSLocalizedString("%@ (%d skills)", comment: ""),
			                               NCTimeIntervalFormatter.localizedString(from: max(0, endDate.timeIntervalSinceNow), precision: .minutes), skillQueue.count)
		}
		else {
			cell.titleLabel?.text = NSLocalizedString("No skills in training", comment: "")
		}
	}
}

fileprivate class NCSkillPlanSection: NCTreeSection {
	init(skillPlan: NCSkillPlan, character: NCCharacter) {
		let skills = skillPlan.skills?.sortedArray(using: [NSSortDescriptor(key: "position", ascending: true)]) as? [NCSkillPlanSkill] ?? []
		
		let invTypes = NCDatabase.sharedDatabase?.invTypes
		let trainingQueue = NCTrainingQueue(character: character)
		for skill in skills {
			guard let type = invTypes?[Int(skill.typeID)] else {continue}
			if let trainedSkill = character.skills[Int(skill.typeID)], trainedSkill.level ?? 0 >= Int(skill.level) {
				skillPlan.remove(skill: skill)
			}
			else {
				trainingQueue.add(skill: type, level: Int(skill.level))
			}
		}
		if skillPlan.managedObjectContext?.hasChanges == true {
			try? skillPlan.managedObjectContext?.save()
		}
		
		let children = trainingQueue.skills.map{ skill in
			return NCSkillPlanRow(skill: skill, character: character)
		}
		let title = NSMutableAttributedString(string: NSLocalizedString("TRAINING PLAN:", comment: ""))
		if let name = skillPlan.name?.uppercased() {
			title.append(NSAttributedString(string: " \(name)", attributes: [NSForegroundColorAttributeName: UIColor.caption]))
		}
		title.append(NSAttributedString(string: " (\(NCTimeIntervalFormatter.localizedString(from: trainingQueue.trainingTime(characterAttributes: character.attributes), precision: .seconds)))"))
		super.init(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "SkillPlan", attributedTitle: title, children: children)
	}
}

class NCSkillQueueViewController: UITableViewController {
	@IBOutlet weak var treeController: NCTreeController!
	
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
	
	//MARK: NCTreeControllerDelegate
	
	func treeController(_ treeController: NCTreeController, cellIdentifierForItem item: AnyObject) -> String {
		return (item as! NCTreeNode).cellIdentifier
	}
	
	func treeController(_ treeController: NCTreeController, configureCell cell: UITableViewCell, withItem item: AnyObject) {
		(item as! NCTreeNode).configure(cell: cell)
	}
	
	func treeController(_ treeController: NCTreeController, canEditChild child:Int, ofItem item: AnyObject?) -> Bool {
		return item is NCSkillPlanSection
	}
	
	func treeController(_ treeController: NCTreeController, editingStyleForChild child: Int, ofItem item: AnyObject?) -> UITableViewCellEditingStyle {
		return item is NCSkillPlanSection ? .delete : .none
	}
	
	//MARK: Private
	
	@objc private func refresh() {
		let progress = NCProgressHandler(totalUnitCount: 1)
		progress.progress.becomeCurrent(withPendingUnitCount: 1)
		reload(cachePolicy: .reloadIgnoringLocalCacheData) {
			self.refreshControl?.endRefreshing()
		}
		progress.progress.resignCurrent()
	}
	
	private func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		if let account = NCAccount.current {
			NCCharacter.load(account: account) { result in
				switch result {
				case let .success(character):
					let skillQueue = NCSkillQueueSection(character: character)
					let skillPlan = NCSkillPlanSection(skillPlan: account.activeSkillPlan!, character: character)
					self.treeController.content = [skillQueue, skillPlan]
					self.treeController.reloadData()
					
				case let .failure(error):
					if self.treeController.content == nil {
						self.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
					}
				}
				completionHandler?()
			}
			
		}
		else {
			completionHandler?()
		}
	}

}
