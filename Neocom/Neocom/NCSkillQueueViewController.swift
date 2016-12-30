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
			cell.trainingTimeLabel?.text = NCTimeIntervalFormatter.localizedString(from: max(skill.trainingEndDate?.timeIntervalSinceNow ?? 0, 0), precision: .minutes)
		}
	}
	
	override var hashValue: Int {
		return skill.hashValue
	}
	
	static func ==(lhs: NCSkillQueueRow, rhs: NCSkillQueueRow) -> Bool {
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
		func rows(_ skillQueue: [NCSkillPlanSkill]) -> [NCSkillQueueRow] {
			return skillQueue.flatMap { (item) in
				guard let type = invTypes?[Int(item.typeID)] else {return nil}
				guard let skill = NCSkill(type: type, level: Int(item.level)) else {return nil}
				return NCSkillQueueRow(skill: skill)
			}
		}

		let children = rows(skills)
		super.init(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "SkillPlan", children: children)
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
			}
			
		}
	}

}
