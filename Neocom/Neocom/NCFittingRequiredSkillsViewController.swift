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
		super.init(prototype: Prototype.NCSkillTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCSkillTableViewCell else {return}
		
		cell.titleLabel?.text = "\(skill.skill.typeName) (x\(skill.skill.rank))"
		cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:min(skill.level, 5))
		let a = NCUnitFormatter.localizedString(from: Double(skill.skill.skillPoints), unit: .none, style: .full)
		let b = NCUnitFormatter.localizedString(from: Double(skill.skill.skillPoints(at: skill.level)), unit: .skillPoints, style: .full)
		cell.spLabel?.text = "\(a) / \(b)"
		let t = skill.trainingTime(characterAttributes: character.attributes)
		cell.trainingTimeLabel?.text = NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes)
		
		let typeID = skill.skill.typeID
		let level = skill.level

		let item = NCAccount.current?.activeSkillPlan?.skills?.first(where: { (skill) -> Bool in
			let skill = skill as! NCSkillPlanSkill
			return Int(skill.typeID) == typeID && Int(skill.level) >= level
		})
		if item != nil {
			cell.iconView?.image = #imageLiteral(resourceName: "skillRequirementQueued")
		}
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
		
		reload()
		
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		treeController.deselectCell(for: node, animated: true)
		if let route = (node as? TreeNodeRoutable)?.route {
			route.perform(source: self, view: treeController.cell(for: node))
		}
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		if let route = (node as? TreeNodeRoutable)?.accessoryButtonRoute {
			route.perform(source: self, view: treeController.cell(for: node))
		}
	}
	
	//MARK: - Private
	
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
							if rows.isEmpty {
								self.tableView.backgroundView = NCTableViewBackgroundLabel(text: NSLocalizedString("No Result", comment: ""))
							}
							else {
								let section = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.default, title: NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds), children: rows)
								section.isExpandable = false
								self.treeController.content = RootNode([section])
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
