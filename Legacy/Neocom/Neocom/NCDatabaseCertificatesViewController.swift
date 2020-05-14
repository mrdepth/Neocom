//
//  NCDatabaseCertificatesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI
import Futures

fileprivate class NCDatabaseCertificateRow: NCFetchedResultsObjectNode<NCDBCertCertificate> {
	var character: NCCharacter?
	var image: UIImage?
	var subtitle: String?
	
	required init(object: NCDBCertCertificate) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		
		cell.object = object
		cell.titleLabel?.text = object.certificateName
		cell.accessoryType = .disclosureIndicator

		if let subtitle = subtitle {
			cell.iconView?.image = image
			cell.subtitleLabel?.text = subtitle
		}
		else  {
			cell.iconView?.image = NCDatabase.sharedDatabase?.eveIcons[NCDBEveIcon.File.certificateUnclaimed.rawValue]?.image?.image
			cell.subtitleLabel?.text = nil
			
			if let character = character {
				NCDatabase.sharedDatabase?.performBackgroundTask{ managedObjectContext in
					let certificate = (try! managedObjectContext.existingObject(with: self.object.objectID)) as! NCDBCertCertificate
					let trainingQueue = NCTrainingQueue(character: character)
					var level: NCDBCertMasteryLevel?
					for mastery in (certificate.masteries?.sortedArray(using: [NSSortDescriptor(key: "level.level", ascending: true)]) as? [NCDBCertMastery]) ?? [] {
						trainingQueue.add(mastery: mastery)
						if !trainingQueue.skills.isEmpty {
							break
						}
						level = mastery.level
					}
					let trainingTime = trainingQueue.trainingTime(characterAttributes: character.attributes)
					let subtitle: String
					let image: UIImage?
					
					if trainingTime > 0 {
						subtitle = String(format: NSLocalizedString("%@ to level %d", comment: ""), NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds), (level?.level ?? -1) + 2)
					}
					else {
						subtitle = ""
					}
					image = level?.icon?.image?.image ?? NCDBEveIcon.eveIcons(managedObjectContext: managedObjectContext)[NCDBEveIcon.File.certificateUnclaimed.rawValue]?.image?.image
					
					DispatchQueue.main.async {
						self.image = image
						self.subtitle = subtitle
						self.treeController?.reloadCells(for: [self])

//						if (cell.object as? NCDBCertCertificate) == self.object {
//							cell.iconView?.image = image
//							cell.subtitleLabel?.text = subtitle
//						}
					}
				}
			}
		}
	}
}

class NCDatabaseCertificatesViewController: NCTreeViewController {

	var group: NCDBInvGroup?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.default])
		title = group?.groupName
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController?.content = nil
		}
	}
	
	override func content() -> Future<TreeNode?> {
		guard let group = group else {return .init(nil)}
		
		let request = NSFetchRequest<NCDBCertCertificate>(entityName: "CertCertificate")
		request.predicate = NSPredicate(format: "group == %@", group)
		request.sortDescriptors = [NSSortDescriptor(key: "certificateName", ascending: true)]
		
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)


		Progress(totalUnitCount: 1).perform {
			NCCharacter.load(account: NCAccount.current).then(on: .main) { character in
				self.treeController?.content?.children.forEach {
					($0 as? NCDatabaseCertificateRow)?.character = character
				}
			}.catch(on: .main) { _ in
				let character = NCCharacter()
				self.treeController?.content?.children.forEach {
					($0 as? NCDatabaseCertificateRow)?.character = character
				}
			}.finally(on: .main) {
				self.tableView.reloadData()
			}
		}
		
		return .init(FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCDatabaseCertificateRow.self))
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCDatabaseCertificateRow else {return}
		Router.Database.CertificateInfo(certificate: row.object).perform(source: self, sender: treeController.cell(for: node))
	}
}
