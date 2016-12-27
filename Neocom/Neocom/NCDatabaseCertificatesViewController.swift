//
//  NCDatabaseCertificatesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

fileprivate class NCDatabaseCertificateRow: NSObject {
	dynamic var subtitle: String?
	dynamic var image: UIImage?
	dynamic var certificate: NCDBCertCertificate?
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
			let request = NSFetchRequest<NCDBCertCertificate>(entityName: "CertCertificate")
			request.predicate = NSPredicate(format: "group == %@", group)
			request.sortDescriptors = [NSSortDescriptor(key: "certificateName", ascending: true)]
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			try? results.performFetch()
			self.results = results
			self.tableView.reloadData()

			
			let progress = NCProgressHandler(totalUnitCount: 1)
			progress.progress.becomeCurrent(withPendingUnitCount: 1)
			NCCharacter.load(account: NCAccount.current) { result in
				self.rows = [:]
				self.character = result
				if let indexPaths = self.tableView.indexPathsForVisibleRows {
					self.tableView.reloadRows(at: indexPaths, with: .none)
				}
				progress.finih()
			}
			progress.progress.resignCurrent()
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			results = nil
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCDatabaseCertificateInfoViewController" {
			let controller = segue.destination as? NCDatabaseCertificateInfoViewController
			controller?.certificate = (sender as? NCDefaultTableViewCell)?.object as? NCDBCertCertificate
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
		cell.subtitleLabel?.text = nil
		
		guard let character = character else {
			cell.iconView?.image = NCDatabase.sharedDatabase?.eveIcons[NCDBEveIcon.File.certificateUnclaimed.rawValue]?.image?.image
			return cell
		}
		
		var row = rows?[indexPath]
		if row == nil {
			row = NCDatabaseCertificateRow()
			row?.image = NCDatabase.sharedDatabase?.eveIcons[NCDBEveIcon.File.certificateUnclaimed.rawValue]?.image?.image
			rows?[indexPath] = row
			
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
				image = level?.icon?.image?.image ?? NCDBEveIcon.eveIcons(managedObjectContext: managedObjectContext)[NCDBEveIcon.File.certificateUnclaimed.rawValue]?.image?.image
				
				DispatchQueue.main.async {
					row?.image = image
					row?.subtitle = subtitle
				}
			}
		}

		cell.binder.bind("subtitleLabel.text", toObject: row!, withKeyPath: "subtitle", transformer: nil)
		cell.binder.bind("iconView.image", toObject: row!, withKeyPath: "image", transformer: nil)
		return cell
	}
	
}
