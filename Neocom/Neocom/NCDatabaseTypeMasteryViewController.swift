//
//  NCDatabaseCertificateMasteryViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

import UIKit
import CoreData

/*
class NCDatabaseCertificateSection: NCTreeSection {
	let trainingQueue: NCTrainingQueue
	let trainingTime: TimeInterval
	let character: NCCharacter
	init(mastery: NCDBCertMastery, character: NCCharacter, children: [NCTreeNode]?) {
		self.character = character
		trainingQueue = NCTrainingQueue(character: character)
		trainingQueue.add(mastery: mastery)
		trainingTime = trainingQueue.trainingTime(characterAttributes: character.attributes)
		let title = NSMutableAttributedString(string: mastery.certificate!.certificateName!.uppercased(), attributes: [NSForegroundColorAttributeName: UIColor.caption])
		if trainingTime > 0 {
			title.append(NSAttributedString(string: " (\(NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds)))", attributes: [NSForegroundColorAttributeName: UIColor.white]))
		}
		
		super.init(cellIdentifier: "NCSkillsHeaderTableViewCell", attributedTitle: title, children: children)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCSkillsHeaderTableViewCell
		cell.titleLabel?.attributedText = attributedTitle
		cell.trainButton?.isHidden = NCAccount.current == nil || trainingTime == 0
		cell.trainingQueue = trainingQueue
		cell.character = character
	}
}
*/

class NCDatabaseTypeMasteryViewController: NCTreeViewController {
	var type: NCDBInvType?
	var level: NCDBCertMasteryLevel?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCActionHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default])
		
		title = NSLocalizedString("Level", comment: "") + " \(String(romanNumber: Int((level?.level ?? 0) + 1)))"
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let type = type, let level = level, treeController?.content == nil {
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
			
			
			progress.progress.becomeCurrent(withPendingUnitCount: 1)
			NCCharacter.load(account: NCAccount.current) { result in
				let character: NCCharacter
				switch result {
				case let .success(value):
					character = value
				default:
					character = NCCharacter()
				}

				NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
					let type = try! managedObjectContext.existingObject(with: type.objectID) as! NCDBInvType
					let level = try! managedObjectContext.existingObject(with: level.objectID) as! NCDBCertMasteryLevel
					
					let request = NSFetchRequest<NCDBCertMastery>(entityName: "CertMastery")
					request.predicate = NSPredicate(format: "level == %@ AND certificate.types CONTAINS %@", level, type)
					request.sortDescriptors = [NSSortDescriptor(key: "certificate.certificateName", ascending: true)]
					
					var certificates = [TreeSection]()
					for mastery in (try? managedObjectContext.fetch(request)) ?? [] {
						
						var rows = [NCDatabaseTypeSkillRow]()
						for skill in mastery.skills?.sortedArray(using: [NSSortDescriptor(key: "type.typeName", ascending: true)]) as? [NCDBCertSkill] ?? [] {
							let row = NCDatabaseTypeSkillRow(skill: skill, character: character)
							rows.append(row)
						}
						let trainingQueue = NCTrainingQueue(character: character)
						trainingQueue.add(mastery: mastery)
						let title = mastery.certificate!.certificateName!.uppercased()
						let section = NCDatabaseSkillsSection(nodeIdentifier: nil, title: title, trainingQueue: trainingQueue, character: character, children: rows)
						section.isExpanded = section.trainingTime > 0
						certificates.append(section)
					}
					progress.progress.completedUnitCount += 1
					
					DispatchQueue.main.async {
						let node = TreeNode()
						node.children = certificates
						self.treeController?.content = node
						progress.finish()
						
					}
				}
			}
			progress.progress.resignCurrent()
		}
	}
	
	// MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		if let item = node as? NCDatabaseSkillsSection {
			performTraining(trainingQueue: item.trainingQueue, character: item.character, sender: treeController.cell(for: node))
		}
	}
	
	// MARK: Private
	
	private func performTraining(trainingQueue: NCTrainingQueue, character: NCCharacter, sender: UITableViewCell?) {
		guard let account = NCAccount.current else {return}
		
		let message = String(format: NSLocalizedString("Total Training Time: %@", comment: ""), NCTimeIntervalFormatter.localizedString(from: trainingQueue.trainingTime(characterAttributes: character.attributes), precision: .seconds))
		
		let controller = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Add to Skill Plan", comment: ""), style: .default) { [weak self] _ in
			account.activeSkillPlan?.add(trainingQueue: trainingQueue)
			
			if account.managedObjectContext?.hasChanges == true {
				try? account.managedObjectContext?.save()
				self?.tableView.reloadData()
			}
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
		present(controller, animated: true)
		controller.popoverPresentationController?.sourceView = sender
		controller.popoverPresentationController?.sourceRect = sender?.bounds ?? .zero
	}
	
}
