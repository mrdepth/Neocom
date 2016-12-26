//
//  NCDatabaseCertificatesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

fileprivate struct NCDatabaseCertificateRow {
	var isLoading: Bool = false
	var subtitle: String?
	var image: UIImage?
	var certificate: NCDBCertCertificate?
}

class NCDatabaseCertificatesViewController: UITableViewController {
	var group: NCDBInvGroup?
	private var results: NSFetchedResultsController<NCDBCertCertificate>?
	private var character: NCCharacter?
	private var rows: [IndexPath: NCDatabaseCertificateRow]?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		title = group?.groupName
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let group = group, results == nil {
			NCCharacter.load(account: NCAccount.current) { result in
				self.character = result
				let request = NSFetchRequest<NCDBCertCertificate>(entityName: "CertCertificate")
				request.predicate = NSPredicate(format: "group == %@", group)
				request.sortDescriptors = [NSSortDescriptor(key: "certificateName", ascending: true)]
				let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
				try? results.performFetch()
				self.results = results
				self.rows = [:]
				self.tableView.reloadData()
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			results = nil
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCDatabaseGroupsViewController" {
			let controller = segue.destination as? NCDatabaseGroupsViewController
			controller?.category = (sender as? NCDefaultTableViewCell)?.object as? NCDBInvCategory
		}
	}
	
	//MARK: UITableViewDataSource
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return results?.sections?.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return results?.sections?[section].numberOfObjects ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NCDefaultTableViewCell
		let object = results?.object(at: indexPath)

		cell.object = object
		cell.titleLabel?.text = object?.certificateName
		cell.iconView?.image = nil
		cell.subtitleLabel?.text = " "
		
		if let row = rows?[indexPath] {
			cell.iconView?.image = row.image
			cell.subtitleLabel?.text = row.subtitle
		}
		else if let character = self.character {
			var row = NCDatabaseCertificateRow()
			row.isLoading = true
			NCDatabase.sharedDatabase?.performBackgroundTask{ managedObjectContext in
				let certificate = (try! managedObjectContext.existingObject(with: object!.objectID)) as! NCDBCertCertificate
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
				image = level?.icon?.image?.image ?? NCDBEveIcon.eveIcons(managedObjectContext: managedObjectContext)[NCDBEveIconName.certificateUnclaimed.rawValue]?.image?.image
				
				DispatchQueue.main.async {
					row.image = image
					row.subtitle = subtitle
					if let obj = cell.object as? NCDBCertCertificate?, obj === object {
						cell.iconView?.image = image
						cell.subtitleLabel?.text = subtitle
					}
				}
			}
			rows?[indexPath] = row
		}
		return cell
	}
	
}
