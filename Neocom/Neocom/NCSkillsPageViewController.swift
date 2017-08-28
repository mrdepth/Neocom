//
//  NCSkillsPageViewController.swift
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
	init(group: NCDBInvGroup, children: [NCSkillRow], skillPoints: Int64?) {
		self.group = group
		let groupName = group.groupName?.uppercased() ?? ""
		let skills = NCUnitFormatter.localizedString(from: children.count, unit: .none, style: .full)
		
		let title: String
		
		if let skillPoints = skillPoints {
			let sp = NCUnitFormatter.localizedString(from: Double(skillPoints), unit: .skillPoints, style: .short)
			title = "\(groupName) (\(skills) \(NSLocalizedString("SKILLS", comment: "")), \(sp)))"
		}
		else {
			title = "\(groupName) (\(skills) \(NSLocalizedString("SKILLS", comment: "")))"
		}
		
		super.init(nodeIdentifier: String(group.groupID), title: title, children: children)
		isExpanded = false
	}
}


class NCSkillsPageViewController: NCPageViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		viewControllers = [NSLocalizedString("My", comment: ""),
		                   NSLocalizedString("Can Train", comment: ""),
		                   NSLocalizedString("Not Known", comment: ""),
		                   NSLocalizedString("All", comment: "")].map { title in
							let controller = storyboard!.instantiateViewController(withIdentifier: "NCSkillsContentViewController") as! NCSkillsContentViewController
							controller.title = title
							return controller
		}

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
		NCCharacter.load(account: NCAccount.current) { result in
			let character: NCCharacter
			switch result {
			case let .success(value):
				character = value
			case .failure:
				character = NCCharacter()
			}
			
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
				var notKnownSections = [NCSkillSection]()
				
				progress.becomeCurrent(withPendingUnitCount: 1)
				let sectionsProgress = Progress(totalUnitCount: Int64(result.sections!.count))
				progress.resignCurrent()
				
				for section in result.sections! {
					var allRows = [NCSkillRow]()
					var myRows = [NCSkillRow]()
					var canTrainRows = [NCSkillRow]()
					var notKnownRows = [NCSkillRow]()
					
					var group: NCDBInvGroup?
					for type in section.objects as? [NCDBInvType] ?? [] {
						let level = map[Int(type.typeID)]?.currentSkillLevel
						
						if let skill = NCSkill(type: type, level: level) {
							if group == nil {
								group = type.group
							}
							
							allRows.append(NCSkillRow(prototype: Prototype.NCSkillTableViewCell.compact, skill: skill, character: character))
							if let level = level {
								myRows.append(NCSkillRow(prototype: Prototype.NCSkillTableViewCell.compact, skill: skill, character: character))
								if level < 5 {
									canTrainRows.append(NCSkillRow(prototype: Prototype.NCSkillTableViewCell.compact, skill: skill, character: character))
								}
							}
							else {
								canTrainRows.append(NCSkillRow(prototype: Prototype.NCSkillTableViewCell.compact, skill: skill, character: character))
								notKnownRows.append(NCSkillRow(prototype: Prototype.NCSkillTableViewCell.compact, skill: skill, character: character))
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
						if !myRows.isEmpty {
							mySections.append(NCSkillSection(group: group, children: myRows, skillPoints: mySP))
						}
						if !canTrainRows.isEmpty {
							canTrainSections.append(NCSkillSection(group: group, children: canTrainRows, skillPoints: totalSP - mySP))
						}
						if !notKnownRows.isEmpty {
							notKnownSections.append(NCSkillSection(group: group, children: notKnownRows, skillPoints: nil))
						}
					}
					sectionsProgress.completedUnitCount += 1
				}
				
				DispatchQueue.main.async {
					self.sections = [mySections, canTrainSections, notKnownSections, allSections]
					(self.viewControllers as? [NCSkillsContentViewController])?.forEach {
						$0.tableView.backgroundView = nil
					}
					
					completionHandler?()
				}
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
