//
//  NCFittingRequiredSkillsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 06.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData

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

class NCFittingRequiredSkillsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	
	var ship: NCFittingShip?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCSkillTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default
			])
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		if let skillPlan = NCAccount.current?.activeSkillPlan {
			if let title = skillPlan.name {
				self.title = title
			}
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Add", comment: ""), style: .done, target: self, action: #selector(onAdd(_:)))
		}
		
		
		reload()
		
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
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		treeController.deselectCell(for: node, animated: true)
		if let route = (node as? TreeNodeRoutable)?.route {
			route.perform(source: self, sender: treeController.cell(for: node))
		}
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		if let route = (node as? TreeNodeRoutable)?.accessoryButtonRoute {
			route.perform(source: self, sender: treeController.cell(for: node))
		}
	}
	
	//MARK: - Private
	
	private var character: NCCharacter?
	private var trainingQueue: NCTrainingQueue?
	
	private func reload() {
		guard let ship = ship else {return}

		
		let progress = NCProgressHandler(totalUnitCount: 2)
		progress.progress.perform {
			NCCharacter.load(account: NCAccount.current) { result in
				switch result {
				case let .success(character):
					let trainingQueue = NCTrainingQueue(character: character)
					NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
						let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
						var typeIDs = Set<Int>()
						ship.engine?.performBlockAndWait {
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
						}
						
						typeIDs.forEach {
							guard let type = invTypes[$0] else {return}
							trainingQueue.addRequiredSkills(for: type)
						}
						
						let rows = trainingQueue.skills.map { NCTrainingSkillRow(skill: $0, character: character) }
						let trainingTime = trainingQueue.trainingTime(characterAttributes: character.attributes)
						
						DispatchQueue.main.async {
							self.character = character
							self.trainingQueue = trainingQueue
							if rows.isEmpty {
								self.tableView.backgroundView = NCTableViewBackgroundLabel(text: NSLocalizedString("No Result", comment: ""))
								self.navigationItem.rightBarButtonItem?.isEnabled = false
							}
							else {
								let section = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.default, title: NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds), children: rows)
								section.isExpandable = false
								self.treeController.content = RootNode([section])
								self.navigationItem.rightBarButtonItem?.isEnabled = true
							}
							progress.finish()
						}
					}
					
				case let .failure(error):
					self.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
				}
			}
		}
		

	}
	
}

