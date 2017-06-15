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

/*
fileprivate class NCSkillRow: NCTreeRow {
	let skill: NCSkill
	init(skill: NCSkill) {
		self.skill = skill
		super.init(cellIdentifier: "NCSkillTableViewCell")
	}
	
	lazy var image: UIImage? = {
		let typeID = Int32(self.skill.typeID)
		return NCAccount.current?.activeSkillPlan?.skills?.first(where: { ($0 as? NCSkillPlanSkill)?.typeID == typeID }) != nil ? #imageLiteral(resourceName: "skillRequirementQueued") : nil
	}()
	
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
			
			cell.iconView?.image = image
		}
	}
}
*/

fileprivate class NCSkillSection: DefaultTreeSection {
	let group: NCDBInvGroup
	init(group: NCDBInvGroup, children: [NCSkillRow], skillPoints: Int64) {
		self.group = group
		//let title = "\(group.groupName?.uppercased() ?? "") (\(children.count))"
		let title = "\(group.groupName?.uppercased() ?? "") (\(NCUnitFormatter.localizedString(from: children.count, unit: .none, style: .full)) \(NSLocalizedString("SKILLS", comment: "")), \(NCUnitFormatter.localizedString(from: Double(skillPoints), unit: .skillPoints, style: .short)))"
		//let title = String(format: NSLocalizedString("%@ (%@)", comment: ""), group.groupName?.uppercased() ?? "", NCUnitFormatter.localizedString(from: Double(sp), unit: .skillPoints, style: .full))
		super.init(nodeIdentifier: String(group.groupID), title: title, children: children)
		isExpanded = false
	}
}


class NCSkillsViewController: NCPageViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let controller1 = storyboard!.instantiateViewController(withIdentifier: "NCSkillsContentViewController") as! NCSkillsContentViewController
		let controller2 = storyboard!.instantiateViewController(withIdentifier: "NCSkillsContentViewController") as! NCSkillsContentViewController
		let controller3 = storyboard!.instantiateViewController(withIdentifier: "NCSkillsContentViewController") as! NCSkillsContentViewController
		controller1.title = NSLocalizedString("My", comment: "")
		controller2.title = NSLocalizedString("Can Train", comment: "")
		controller3.title = NSLocalizedString("All", comment: "")
		viewControllers = [controller1, controller2, controller3]
	}
	
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if sections == nil {
			reload()
		}
	}
	

	
	//MARK: Private
	
	private var observer: NCManagedObjectObserver?
	private var sections: [[NCSkillSection]]? {
		didSet {
			viewControllers?.enumerated().forEach {
				($0.element as? NCSkillsContentViewController)?.content = sections?[$0.offset]
			}
		}
	}
	
	private func process(_ value: ESI.Skills.CharacterSkills, dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		let progress = Progress(totalUnitCount: 1)
		NCDatabase.sharedDatabase?.performBackgroundTask{ managedObjectContext in
			let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
			request.predicate = NSPredicate(format: "published == TRUE AND group.category.categoryID == %d", NCDBCategoryID.skill.rawValue)
			
			request.sortDescriptors = [NSSortDescriptor(key: "group.groupName", ascending: true), NSSortDescriptor(key: "typeName", ascending: true)]
			let result = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "group.groupName", cacheName: nil)
			try! result.performFetch()
			
			var map: [Int: ESI.Skills.CharacterSkills.Skill] = [:]
			value.skills?.forEach {map[$0.skillID ?? 0] = $0}
			
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
						
						allRows.append(NCSkillRow(prototype: Prototype.NCSkillTableViewCell.compact, skill: skill))
						if let level = level {
							myRows.append(NCSkillRow(prototype: Prototype.NCSkillTableViewCell.compact, skill: skill))
							if level < 5 {
								canTrainRows.append(NCSkillRow(prototype: Prototype.NCSkillTableViewCell.compact, skill: skill))
							}
						}
						else {
							canTrainRows.append(NCSkillRow(prototype: Prototype.NCSkillTableViewCell.compact, skill: skill))
						}
					}
				}
				if let group = group {
					var mySP = 0 as Int64
					var totalSP = 0 as Int64
					allRows.forEach {
						mySP += Int64($0.skill.skillPoints)
						for i in 1...5 {
							totalSP += Int64($0.skill.skillPoints(at: i))
						}
					}

					allSections.append(NCSkillSection(group: group, children: allRows, skillPoints: totalSP))
					if myRows.count > 0 {
						mySections.append(NCSkillSection(group: group, children: myRows, skillPoints: mySP))
					}
					if canTrainRows.count > 0 {
						canTrainSections.append(NCSkillSection(group: group, children: canTrainRows, skillPoints: totalSP - mySP))
					}
				}
				sectionsProgress.completedUnitCount += 1
			}
			
			DispatchQueue.main.async {
				self.sections = [mySections, canTrainSections, allSections]
				(self.viewControllers as? [NCSkillsContentViewController])?.forEach {
					$0.tableView.backgroundView = nil
				}

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
				case let .success(value, cacheRecord):
					if let cacheRecord = cacheRecord {
						self.observer = NCManagedObjectObserver(managedObject: cacheRecord) { [weak self] _, _ in
							guard let value = cacheRecord.data?.data as? ESI.Skills.CharacterSkills else {return}
							self?.process(value, dataManager: dataManager, completionHandler: nil)
						}
					}
					progress.progress.becomeCurrent(withPendingUnitCount: 1)
					self.process(value, dataManager: dataManager) {
						progress.finish()
						completionHandler?()
					}
					progress.progress.resignCurrent()
				case let .failure(error):
					(self.viewControllers as? [NCSkillsContentViewController])?.forEach {
						if $0.content == nil {
							$0.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
						}
					}
				}
			}
			progress.progress.resignCurrent()
		}
	}
	
}
