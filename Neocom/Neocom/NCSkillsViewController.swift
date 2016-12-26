//
//  NCSkillsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI

fileprivate class NCSkillRow: NCTreeRow {
	let skill: NCSkill
	init(skill: NCSkill) {
		self.skill = skill
		super.init(cellIdentifier: "NCSkillTableViewCell")
	}
	
	fileprivate override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCSkillTableViewCell {
			cell.titleLabel?.text = "\(skill.typeName) (x\(skill.rank))"
			if let level = skill.level {
				cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:level)
				
			}
			else {
				cell.levelLabel?.text = nil
			}
			
			let level = (skill.level ?? 0)
			if level < 5 {
				cell.trainingTimeLabel?.text = String(format: NSLocalizedString("%@ ", comment: ""),
				                                      //String(romanNumber:level + 1),
				                                      NCTimeIntervalFormatter.localizedString(from: skill.trainingTimeToLevelUp(characterAttributes: NCCharacterAttributes()), precision: .seconds))
				
			}
			else {
				cell.trainingTimeLabel?.text = NSLocalizedString("COMPLETED", comment: "")
			}
			
			
//			let a = NCUnitFormatter.localizedString(from: Double(skill.skillPoints), unit: .none, style: .full)
//			let b = NCUnitFormatter.localizedString(from: Double(skill.skillPoints(at: skill.level + 1)), unit: .skillPoints, style: .full)
//			cell.spLabel?.text = "\(a) / \(b)"
//			cell.trainingTimeLabel?.text = NCTimeIntervalFormatter.localizedString(from: max(skill.trainingEndDate?.timeIntervalSinceNow ?? 0, 0), precision: .minutes)
		}
	}
}

fileprivate class NCSkillSection: NCTreeSection {
	let group: NCDBInvGroup
	init(group: NCDBInvGroup, children: [NCSkillRow], skillPoints: Int64) {
		self.group = group
		//let title = "\(group.groupName?.uppercased() ?? "") (\(children.count))"
		let title = "\(group.groupName?.uppercased() ?? "") (\(NCUnitFormatter.localizedString(from: Double(skillPoints), unit: .skillPoints, style: .full)))"
		//let title = String(format: NSLocalizedString("%@ (%@)", comment: ""), group.groupName?.uppercased() ?? "", NCUnitFormatter.localizedString(from: Double(sp), unit: .skillPoints, style: .full))
		super.init(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: String(group.groupID), title: title, children: children)
	}
}


class NCSkillsViewController: UITableViewController, NCTreeControllerDelegate {
	@IBOutlet weak var treeController: NCTreeController!
	@IBOutlet weak var segmentedControl: UISegmentedControl!
	
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
	
	@IBAction func onChangeSegment(_ sender: Any) {
		self.treeController.content = self.sections?[self.segmentedControl.selectedSegmentIndex]
		self.treeController.reloadData()
	}
	
	//MARK: NCTreeControllerDelegate
	
	func treeController(_ treeController: NCTreeController, cellIdentifierForItem item: AnyObject) -> String {
		return (item as! NCTreeNode).cellIdentifier
	}
	
	func treeController(_ treeController: NCTreeController, configureCell cell: UITableViewCell, withItem item: AnyObject) {
		(item as! NCTreeNode).configure(cell: cell)
	}
	
	func treeController(_ treeController: NCTreeController, isItemExpanded item: AnyObject) -> Bool {
		guard let node = (item as? NCTreeNode)?.nodeIdentifier else {return false}
		let setting = NCSetting.setting(key: "NCSkillsViewController.\(node)")
		return setting?.value as? Bool ?? false
	}
	
	func treeController(_ treeController: NCTreeController, didExpandCell cell: UITableViewCell, withItem item: AnyObject) {
		guard let node = (item as? NCTreeNode)?.nodeIdentifier else {return}
		let setting = NCSetting.setting(key: "NCSkillsViewController.\(node)")
		setting?.value = true as NSNumber
	}
	
	func treeController(_ treeController: NCTreeController, didCollapseCell cell: UITableViewCell, withItem item: AnyObject) {
		guard let node = (item as? NCTreeNode)?.nodeIdentifier else {return}
		let setting = NCSetting.setting(key: "NCSkillsViewController.\(node)")
		setting?.value = false as NSNumber
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
	
	private var observer: NCManagedObjectObserver?
	private var sections: [[NCSkillSection]]?
	
	private func process(_ value: ESSkills, dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		let progress = Progress(totalUnitCount: 1)
		NCDatabase.sharedDatabase?.performBackgroundTask{ managedObjectContext in
			let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
			request.predicate = NSPredicate(format: "published == TRUE AND group.category.categoryID == %d", NCDBCategoryID.skill.rawValue)
			
			request.sortDescriptors = [NSSortDescriptor(key: "group.groupName", ascending: true), NSSortDescriptor(key: "typeName", ascending: true)]
			let result = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "group.groupName", cacheName: nil)
			try! result.performFetch()
			
			var map = [Int: ESSkill]()
			value.skills.forEach {map[$0.skillID] = $0}
			
			var allSections = [NCSkillSection]()
			var mySections = [NCSkillSection]()
			var canTrainSections = [NCSkillSection]()
			
			progress.becomeCurrent(withPendingUnitCount: 1)
			let sectionsProgress = Progress(totalUnitCount: Int64(result.sections!.count))
			progress.resignCurrent()

			for section in result.sections! {
				var allRows = [NCSkillRow]()
				var myRows = [NCSkillRow]()
				var canTrainRows = [NCSkillRow]()
				
				var group: NCDBInvGroup?
				for type in section.objects as? [NCDBInvType] ?? [] {
					let level = map[Int(type.typeID)]?.currentSkillLevel
					
					if let skill = NCSkill(type: type, level: level) {
						if group == nil {
							group = type.group
						}
						
						allRows.append(NCSkillRow(skill: skill))
						if let level = level {
							myRows.append(NCSkillRow(skill: skill))
							if level < 5 {
								canTrainRows.append(NCSkillRow(skill: skill))
							}
						}
						else {
							canTrainRows.append(NCSkillRow(skill: skill))
						}
					}
				}
				if let group = group {
					var sp = 0 as Int64
					allRows.forEach { sp += $0.skill.skillPoints }

					allSections.append(NCSkillSection(group: group, children: allRows, skillPoints: sp))
					if myRows.count > 0 {
						mySections.append(NCSkillSection(group: group, children: myRows, skillPoints: sp))
					}
					if canTrainRows.count > 0 {
						canTrainSections.append(NCSkillSection(group: group, children: canTrainRows, skillPoints: sp))
					}
				}
				sectionsProgress.completedUnitCount += 1
			}
			
			DispatchQueue.main.async {
				self.sections = [mySections, canTrainSections, allSections]
				self.treeController.content = self.sections?[self.segmentedControl.selectedSegmentIndex]
				self.treeController.reloadData()
				self.tableView.backgroundView = nil
				completionHandler?()
			}
		}
	}
	
	private func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		if let account = NCAccount.current {
			let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
			
			progress.progress.becomeCurrent(withPendingUnitCount: 1)
			dataManager.skills { result in
				switch result {
				case let .success(value: value, cacheRecordID: recordID):
					self.observer = NCManagedObjectObserver(managedObjectID: recordID) { [weak self] _, _ in
						guard let record = (try? NCCache.sharedCache?.viewContext.existingObject(with: recordID)) as? NCCacheRecord else {return}
						guard let value = record.data?.data as? ESSkills else {return}
						self?.process(value, dataManager: dataManager, completionHandler: nil)
					}
					progress.progress.becomeCurrent(withPendingUnitCount: 1)
					self.process(value, dataManager: dataManager) {
						progress.finih()
						completionHandler?()
					}
					progress.progress.resignCurrent()
				case let .failure(error):
					if self.treeController.content == nil {
						self.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
					}
				}
			}
			progress.progress.resignCurrent()
		}
	}
	
}
