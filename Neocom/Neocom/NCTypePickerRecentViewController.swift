//
//  NCTypePickerRecentViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCTypePickerRecentViewController: UITableViewController, NSFetchedResultsControllerDelegate {
	private var results: NSFetchedResultsController<NCCacheTypePickerRecent>?
	private var searchController: UISearchController?
	
	private lazy var invTypes = NCDatabase.sharedDatabase?.invTypes
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if results == nil {
			guard let typePickerController = navigationController as? NCTypePickerViewController else {return}
			guard let category = typePickerController.category else {return}
			guard let context = NCCache.sharedCache?.viewContext else {return}
			
			
			let request = NSFetchRequest<NCCacheTypePickerRecent>(entityName: "TypePickerRecent")
			request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
			request.predicate = NSPredicate(format: "category == %d AND subcategory == %d AND raceID == %d", category.category, category.subcategory, category.race?.raceID ?? 0)
			request.fetchBatchSize = 30
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
			results.delegate = self
			try? results.performFetch()
			self.results = results
			
			tableView.backgroundView = (results.fetchedObjects?.count ?? 0) == 0 ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
			tableView.reloadData()
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			results = nil
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCDatabaseTypeInfoViewController" {
			let controller = segue.destination as? NCDatabaseTypeInfoViewController
			let object = (sender as! NCDefaultTableViewCell).object as! NCDBInvType
			controller?.type = object
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
		
		cell.object = nil
		cell.titleLabel?.text = NSLocalizedString("Unknown", comment: "")
		cell.iconView?.image = nil
		if let recent = results?.object(at: indexPath) {
			if let type = invTypes?[Int(recent.typeID)] {
				cell.object = type
				cell.titleLabel?.text = type.typeName
				cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			}
			else {
				DispatchQueue.main.async {
					guard let context = recent.managedObjectContext else {return}
					context.delete(recent)
					if context.hasChanges {
						try? context.save()
					}
				}
			}
		}
		
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if let name = self.results?.sections?[section].name, name == "0" {
			return NSLocalizedString("Unpublished", comment: "")
		}
		else {
			return nil
		}
	}
	
	//MARK: UITableViewDelegate
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let typePickerController = navigationController as? NCTypePickerViewController else {return}
		guard let recent = results?.object(at: indexPath) else {return}
		guard let type = invTypes?[Int(recent.typeID)] else {return}
		guard let context = recent.managedObjectContext else {return}
		
		recent.date = Date() as NSDate
		if context.hasChanges {
			try? context.save()
		}
		typePickerController.completionHandler(typePickerController, type)
	}
	
	// MARK: - NSFetchedResultsControllerDelegate
	
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .delete:
			tableView.deleteRows(at: [indexPath!], with: .bottom)
		case .insert:
			tableView.insertRows(at: [newIndexPath!], with: .bottom)
		case .move:
			tableView.moveRow(at: indexPath!, to: newIndexPath!)
		case .update:
			tableView.reloadRows(at: [newIndexPath!], with: .fade)
		}
	}
	
	
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		switch type {
		case .delete:
			tableView.deleteSections(IndexSet(integer: sectionIndex), with: .bottom)
		case .insert:
			tableView.insertSections(IndexSet(integer: sectionIndex), with: .bottom)
		default:
			break
		}
	}
	
	
	public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}
	
	
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
	}

	
}
