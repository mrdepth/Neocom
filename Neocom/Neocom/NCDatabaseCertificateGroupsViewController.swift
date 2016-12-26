//
//  NCDatabaseCertificateGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCDatabaseCertificateGroupsViewController: UITableViewController {
	private var results: NSFetchedResultsController<NCDBInvGroup>?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if results == nil {
			let request = NSFetchRequest<NCDBInvGroup>(entityName: "InvGroup")
			request.predicate = NSPredicate(format: "certificates.@count > 0")
			request.sortDescriptors = [NSSortDescriptor(key: "groupName", ascending: true)]
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			try? results.performFetch()
			self.results = results
			tableView.reloadData()
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			results = nil
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCDatabaseCertificatesViewController" {
			let controller = segue.destination as? NCDatabaseCertificatesViewController
			controller?.group = (sender as? NCDefaultTableViewCell)?.object as? NCDBInvGroup
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
		cell.titleLabel?.text = object?.groupName
		cell.iconView?.image = object?.icon?.image?.image ?? NCDBEveIcon.defaultCategory.image?.image
		return cell
	}
	
}
