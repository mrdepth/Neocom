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

class NCDatabaseCertificateSection: NCTreeSection {
	let trainingQueue: NCTrainingQueue
	let trainingTime: TimeInterval
	init(mastery: NCDBCertMastery, character: NCCharacter, children: [NCTreeNode]?) {
		trainingQueue = NCTrainingQueue(character: character)
		trainingQueue.add(mastery: mastery)
		trainingTime = trainingQueue.trainingTime(characterAttributes: character.attributes)
		let title = NSMutableAttributedString(string: mastery.certificate!.certificateName!.uppercased(), attributes: [NSForegroundColorAttributeName: UIColor.caption])
		if trainingTime > 0 {
			title.append(NSAttributedString(string: "\n(\(NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds)))", attributes: [NSForegroundColorAttributeName: UIColor.white]))
		}
		
		super.init(cellIdentifier: "NCHeaderTableViewCell", attributedTitle: title, children: children)
	}
}

class NCDatabaseCertificateMasteryViewController: UITableViewController, NCTreeControllerDelegate {
	var type: NCDBInvType?
	var level: NCDBCertMasteryLevel?
	
	private var results: [NCTreeSection]?
	
	@IBOutlet var treeController: NCTreeController!
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.childrenKeyPath = "children"
		treeController.delegate = self
		title = String(format: NSLocalizedString("LEVEL %d", comment: ""), Int(level?.level ?? 0) + 1)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if results == nil, let type = type, let level = level {
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
			
			
			progress.progress.becomeCurrent(withPendingUnitCount: 1)
			NCCharacter.load(account: NCAccount.current) { character in
				NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
					let type = try! managedObjectContext.existingObject(with: type.objectID) as! NCDBInvType
					let level = try! managedObjectContext.existingObject(with: level.objectID) as! NCDBCertMasteryLevel
					
					let request = NSFetchRequest<NCDBCertMastery>(entityName: "CertMastery")
					request.predicate = NSPredicate(format: "level == %@ AND certificate.types CONTAINS %@", level, type)
					request.sortDescriptors = [NSSortDescriptor(key: "certificate.certificateName", ascending: true)]
					
					var certificates = [NCTreeSection]()
					for mastery in (try? managedObjectContext.fetch(request)) ?? [] {
						
						var rows = [NCDatabaseCertSkillRow]()
						for skill in mastery.skills?.sortedArray(using: [NSSortDescriptor(key: "type.typeName", ascending: true)]) as? [NCDBCertSkill] ?? [] {
							let row = NCDatabaseCertSkillRow(skill: skill, character: character)
							rows.append(row)
						}
						let section = NCDatabaseCertificateSection(mastery: mastery, character: character, children: rows)
						section.expanded = section.trainingTime > 0
						certificates.append(section)
					}
					progress.progress.completedUnitCount += 1
					
					DispatchQueue.main.async {
						self.results = certificates
						self.treeController.content = certificates
						self.treeController.reloadData()
						progress.finih()
					}
				}
			}
			progress.progress.resignCurrent()
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCDatabaseTypeInfoViewController" {
			let controller = segue.destination as? NCDatabaseTypeInfoViewController
			let object = (sender as! NCDefaultTableViewCell).object as! NSManagedObjectID
			controller?.type = (try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: object)) as? NCDBInvType
		}
	}
	
	// MARK: NCTreeControllerDelegate
	
	func treeController(_ treeController: NCTreeController, cellIdentifierForItem item: AnyObject) -> String {
		return (item as! NCTreeNode).cellIdentifier
	}
	
	func treeController(_ treeController: NCTreeController, configureCell cell: UITableViewCell, withItem item: AnyObject) {
		(item as! NCTreeNode).configure(cell: cell)
	}
	
	func treeController(_ treeController: NCTreeController, isItemExpanded item: AnyObject) -> Bool {
		return (item as? NCTreeSection)?.expanded ?? true
	}
	
	func treeController(_ treeController: NCTreeController, didExpandCell cell: UITableViewCell, withItem item: AnyObject) {
		(item as? NCTreeSection)?.expanded = true
	}
	
	func treeController(_ treeController: NCTreeController, didCollapseCell cell: UITableViewCell, withItem item: AnyObject) {
		(item as? NCTreeSection)?.expanded = false
	}
}
