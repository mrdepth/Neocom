//
//  NCFittingAffectingSkillsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.06.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CloudData
import Dgmpp
import EVEAPI
import CoreData
import Futures

class NCFittingAffectingSkillsViewController: NCTreeViewController {
	
	var ship: DGMShip?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCSkillTableViewCell.default,
							Prototype.NCHeaderTableViewCell.default
			])
	}
	
	override func content() -> Future<TreeNode?> {
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
	}
	
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

