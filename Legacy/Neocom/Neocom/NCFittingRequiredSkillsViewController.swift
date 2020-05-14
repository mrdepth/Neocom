//
//  NCFittingRequiredSkillsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 06.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData
import Dgmpp
import EVEAPI
import CoreData
import Futures

class NCTrainingSkillRow: TreeRow {
	let skill: NCTrainingSkill
	let character: NCCharacter
	
	init(skill: NCTrainingSkill, character: NCCharacter) {
		self.skill = skill
		self.character = character
		super.init(prototype: Prototype.NCSkillTableViewCell.default, route: Router.Database.TypeInfo(skill.skill.typeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCSkillTableViewCell else {return}
		
		cell.titleLabel?.text = "\(skill.skill.typeName) (x\(Int(skill.skill.rank)))"
		cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:min(skill.level, 5))
		let a = NCUnitFormatter.localizedString(from: Double(skill.skill.skillPoints), unit: .none, style: .full)
		let b = NCUnitFormatter.localizedString(from: Double(skill.skill.skillPoints(at: skill.level)), unit: .skillPoints, style: .full)
		cell.spLabel?.text = "\(a) / \(b)"
		let t = skill.trainingTime(characterAttributes: character.attributes)
		cell.trainingTimeLabel?.text = NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes)
		cell.progressView?.progress = 0
		
		let typeID = skill.skill.typeID
		let level = skill.level

		let item = NCAccount.current?.activeSkillPlan?.skills?.first(where: { (skill) -> Bool in
			let skill = skill as! NCSkillPlanSkill
			return Int(skill.typeID) == typeID && Int(skill.level) >= level
		})
		cell.iconView?.image = item != nil ? #imageLiteral(resourceName: "skillRequirementQueued") : nil
	}
}

class NCFittingRequiredSkillsViewController: NCTreeViewController {
	
	var ship: DGMShip?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCSkillTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default
			])
		if let skillPlan = NCAccount.current?.activeSkillPlan {
			if let title = skillPlan.name {
				self.title = title
			}
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Add", comment: ""), style: .done, target: self, action: #selector(onAdd(_:)))
		}
		
	}
	
	override func content() -> Future<TreeNode?> {
		guard let ship = ship else {
			return .init(nil)
		}
		
		let progress = Progress(totalUnitCount: 2)
		return progress.perform {
			return NCCharacter.load(account: NCAccount.current).then(on: .main) { character -> Future<TreeNode?> in
				let trainingQueue = NCTrainingQueue(character: character)
				return NCDatabase.sharedDatabase!.performBackgroundTask { managedObjectContext -> TreeNode? in
					let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
					var typeIDs = Set<Int>()
					typeIDs.insert(ship.typeID)
					ship.modules.forEach {
						typeIDs.insert($0.typeID)
						if let charge = $0.charge {
							typeIDs.insert(charge.typeID)
						}
					}
					ship.drones.forEach {
						typeIDs.insert($0.typeID)
					}
					
					typeIDs.forEach {
						guard let type = invTypes[$0] else {return}
						trainingQueue.addRequiredSkills(for: type)
					}
					
					let rows = trainingQueue.skills.map { NCTrainingSkillRow(skill: $0, character: character) }
					let trainingTime = trainingQueue.trainingTime(characterAttributes: character.attributes)
					
					guard !rows.isEmpty else {throw NCTreeViewControllerError.noResult}
					let section = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.default, title: NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds), children: rows)
					section.isExpandable = false
					
					DispatchQueue.main.async {
						self.character = character
						self.trainingQueue = trainingQueue
						self.navigationItem.rightBarButtonItem?.isEnabled = !rows.isEmpty
					}
					return RootNode([section])
				}
			}
		}
	}
	
	/*override func content() -> Future<TreeNode?> {
		guard let ship = ship else {
			return .init(nil)
		}
		
		let progress = Progress(totalUnitCount: 2)
		return progress.perform {
			var dic = [DGMTypeID: DGMType]()
			dic[ship.typeID] = ship
			ship.modules.forEach { dic[$0.typeID] = $0 }
			ship.drones.forEach { dic[$0.typeID] = $0 }
			var typeIDs = Set<DGMTypeID>()
			dic.values.forEach { $0.affectors.compactMap {$0 as? DGMSkill}.forEach {typeIDs.insert($0.typeID)} }
			
			
			return NCCharacter.load(account: NCAccount.current).then(on: .main) { character -> Future<TreeNode?> in
				self.character = character
				return NCDatabase.sharedDatabase!.performBackgroundTask{ managedObjectContext -> (TreeNode, NCTrainingQueue) in
					let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
					let trainingQueue = NCTrainingQueue(character: character)
					dic.keys.compactMap {invTypes[$0]}.forEach {trainingQueue.addRequiredSkills(for: $0)}
					
					let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
					request.predicate = NSPredicate(format: "published == TRUE AND group.category.categoryID == %d AND typeID in %@", NCDBCategoryID.skill.rawValue, typeIDs)
					
					request.sortDescriptors = [NSSortDescriptor(key: "group.groupName", ascending: true), NSSortDescriptor(key: "typeName", ascending: true)]
					let result = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "group.groupName", cacheName: nil)
					try! result.performFetch()
					
					var map: [Int: NCSkill] = [:]
					character.skills.forEach {map[$1.typeID] = $1}
					
					var sections = [NCSkillSection]()
					
					progress.becomeCurrent(withPendingUnitCount: 1)
					let sectionsProgress = Progress(totalUnitCount: Int64(result.sections!.count))
					progress.resignCurrent()
					
					for section in result.sections! {
						var rows = [NCSkillRow]()
						
						var group: NCDBInvGroup?
						for type in section.objects as? [NCDBInvType] ?? [] {
							guard let skill = map[Int(type.typeID)] ?? NCSkill(type: type) else {continue}
							
							if group == nil {
								group = type.group
							}
							
							rows.append(NCSkillRow(skill: skill, character: character))
						}
						if let group = group {
							var mySP = 0 as Int64
							var totalSP = 0 as Int64
							rows.forEach {
								mySP += Int64($0.skill.skillPoints)
								for i in 1...5 {
									totalSP += Int64($0.skill.skillPoints(at: i))
								}
							}
							let section = NCSkillSection(group: group, children: rows, skillPoints: totalSP)
							section.isExpanded = true
							sections.append(section)
						}
						sectionsProgress.completedUnitCount += 1
					}
					return (RootNode(sections), trainingQueue)
				}.then(on: .main) { (node, trainingQueue) -> TreeNode in
					self.trainingQueue = trainingQueue
					if NCAccount.current?.activeSkillPlan != nil, trainingQueue.skills.count > 0 {
						self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Add", comment: ""), style: .done, target: self, action: #selector(NCFittingRequiredSkillsViewController.onAdd(_:)))
					}
					return node
				}
			}
		}
	}*/
	
	@objc func onAdd(_ sender: UIBarButtonItem) {
		guard let character = self.character, let trainingQueue = self.trainingQueue else {return}
		guard let account = NCAccount.current else {return}
		
		let message = String(format: NSLocalizedString("Total Training Time: %@", comment: ""), NCTimeIntervalFormatter.localizedString(from: trainingQueue.trainingTime(characterAttributes: character.attributes), precision: .seconds))
		
		let controller = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Add to Skill Plan", comment: ""), style: .default) { [weak self] _ in
			account.activeSkillPlan?.add(trainingQueue: trainingQueue)
			
			if account.managedObjectContext?.hasChanges == true {
				try? account.managedObjectContext?.save()
				self?.dismiss(animated: true, completion: nil)
			}
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
		present(controller, animated: true)
		controller.popoverPresentationController?.barButtonItem = sender

		
	}
	
	//MARK: - Private
	
	private var character: NCCharacter?
	private var trainingQueue: NCTrainingQueue?
	
}

