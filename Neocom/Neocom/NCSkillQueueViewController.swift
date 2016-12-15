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
		super.init(cellIdentifier: "NCTableViewSkillCell")
	}
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCTableViewSkillCell {
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
	var observer: NCManagedObjectObserver?
	let cacheRecord: NCCacheRecord
	
	init(cacheRecord: NCCacheRecord) {
		self.cacheRecord = cacheRecord
		
		var children = [NCSkillQueueRow]()
		let date = Date()
		if let invTypes = NCDatabase.sharedDatabase?.invTypes,
			let skillQueue = (cacheRecord.data?.data as? [ESSkillQueueItem])?.filter({return $0.finishDate != nil && $0.finishDate! > date}) {
			for item in skillQueue {
				guard let type = invTypes[item.skillID] else {continue}
				guard let skill = NCSkill(type: type, skill: item) else {continue}
				let row = NCSkillQueueRow(skill: skill)
				children.append(row)
			}
		}

		super.init(cellIdentifier: "NCTableViewHeaderCell", nodeIdentifier: "SkillQueue", children: children)

		self.observer = NCManagedObjectObserver(managedObjectID: cacheRecord.objectID) { [weak self] (updated, deleted) in
			guard let strongSelf = self else {return}
			guard let skillQueue = (cacheRecord.data?.data as? [ESSkillQueueItem])?.filter({return $0.finishDate != nil && $0.finishDate! > date}) else {return}
			guard let invTypes = NCDatabase.sharedDatabase?.invTypes else {return}
			
			var to = [NCSkillQueueRow]()
			
			for item in skillQueue {
				guard let type = invTypes[item.skillID] else {continue}
				guard let skill = NCSkill(type: type, skill: item) else {continue}
				let row = NCSkillQueueRow(skill: skill)
				to.append(row)
			}

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
		if let cell = cell as? NCTableViewHeaderCell,
			let skillQueue = (cacheRecord.data?.data as? [ESSkillQueueItem])?.filter({return $0.finishDate != nil && $0.finishDate! > date}) {
			if let lastSkill = skillQueue.last, let endDate = lastSkill.finishDate {
				cell.titleLabel?.text = String(format: NSLocalizedString("%@ (%d skills)", comment: ""),
				NCTimeIntervalFormatter.localizedString(from: max(0, endDate.timeIntervalSinceNow), precision: .minutes), skillQueue.count)
			}
			else {
				cell.titleLabel?.text = NSLocalizedString("No skills in training", comment: "")
			}
		}
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
			let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
			
			dataManager.skillQueue { result in
				switch result {
				case let .success(value: _, cacheRecordID: recordID):
					let section = NCSkillQueueSection(cacheRecord: (try! NCCache.sharedCache!.viewContext.existingObject(with: recordID)) as! NCCacheRecord)
					self.treeController.content = [section]
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
