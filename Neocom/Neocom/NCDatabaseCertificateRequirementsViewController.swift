//
//  NCDatabaseCertificateRequirementsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCDatabaseCertTypeRow: NCFetchedResultsObjectNode<NCDBInvType> {
	var character: NCCharacter?
	var subtitle: String?
	
	required init(object: NCDBInvType) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCDefaultTableViewCell
		cell.titleLabel?.text = object.typeName
		cell.iconView?.image = object.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.object = object
		cell.accessoryType = .disclosureIndicator
		
		if let subtitle = subtitle {
			cell.subtitleLabel?.text = subtitle
		}
		else {
			cell.subtitleLabel?.text = nil
			if let character = character {
				NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
					let type = try! managedObjectContext.existingObject(with: self.object.objectID) as! NCDBInvType
					let trainingQueue = NCTrainingQueue(character: character)
					trainingQueue.addRequiredSkills(for: type)
					let trainingTime = trainingQueue.trainingTime(characterAttributes: character.attributes)
					let subtitle = trainingTime > 0 ? NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : ""
					
					DispatchQueue.main.async {
						self.subtitle = subtitle
						if (cell.object as? NCDBInvType) == self.object {
							cell.subtitleLabel?.text = subtitle
						}
					}
				}
			}
		}
	}
	
}

class NCDatabaseCertificateRequirementsViewController: NCTreeViewController {
	var certificate: NCDBCertCertificate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default,
		                    ])
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let certificate = certificate, treeController?.content == nil {
			
			let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
			request.predicate = NSPredicate(format: "published = TRUE AND ANY certificates == %@", certificate)
			request.sortDescriptors = [NSSortDescriptor(key: "group.groupName", ascending: true), NSSortDescriptor(key: "typeName", ascending: true)]
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: "group.groupName", cacheName: nil)
			
			treeController?.content = FetchedResultsNode(resultsController: results, sectionNode: NCDefaultFetchedResultsSectionNode<NCDBInvType>.self, objectNode: NCDatabaseCertTypeRow.self)

			
			let progress = NCProgressHandler(totalUnitCount: 1)
			progress.progress.becomeCurrent(withPendingUnitCount: 1)
			NCCharacter.load(account: NCAccount.current) { result in
				let character: NCCharacter
				switch result {
				case let .success(value):
					character = value
				default:
					character = NCCharacter()
				}
				
				self.treeController?.content?.children.forEach {
					$0.children.forEach { row in
						(row as? NCDatabaseCertTypeRow)?.character = character
					}
				}
				progress.finish()
				self.tableView.reloadData()
			}
			progress.progress.resignCurrent()
		}
	}
	
	// MARK: TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCDatabaseCertTypeRow else {return}
		Router.Database.TypeInfo(row.object).perform(source: self, sender: treeController.cell(for: node))
	}
	
}
