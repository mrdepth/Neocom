//
//  NCFittingEditorViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFittingEditorViewController: NCPageViewController {
	var fleet: NCFittingFleet?
	var engine: NCFittingEngine?
	
	private var observer: NSObjectProtocol?
	private var isModified: Bool = false {
		didSet {
			guard oldValue != isModified else {return}
			
			if isModified {
				navigationItem.setLeftBarButton(UIBarButtonItem(title: NSLocalizedString("Back", comment: "Navigation item"), style: .plain, target: self, action: #selector(onBack(_:))), animated: true)
			}
			else {
				
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		viewControllers = [
			storyboard!.instantiateViewController(withIdentifier: "NCFittingModulesViewController"),
			storyboard!.instantiateViewController(withIdentifier: "NCFittingDronesViewController"),
			storyboard!.instantiateViewController(withIdentifier: "NCFittingImplantsViewController"),
			storyboard!.instantiateViewController(withIdentifier: "NCFittingFleetViewController"),
			storyboard!.instantiateViewController(withIdentifier: "NCFittingStatsViewController"),
		]
		
		observer = NotificationCenter.default.addObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
			self?.isModified = true
		}

	}
	
	@objc private func onBack(_ sender: Any) {
		let controller = UIAlertController(title: nil, message: NSLocalizedString("Save Changes?", comment: ""), preferredStyle: .alert)
		controller.addAction(UIAlertAction(title: NSLocalizedString("Save and Exit", comment: ""), style: .default, handler: {[weak self] _ in
			guard let fleet = self?.fleet else {return}
			
			NCStorage.sharedStorage?.performBackgroundTask {managedObjectContext in
				self?.engine?.performBlockAndWait {
					for (character, objectID) in fleet.pilots {
						guard let ship = character.ship else {continue}
						if let objectID = objectID, let loadout = (try? managedObjectContext.existingObject(with: objectID)) as? NCLoadout {
							loadout.name = ship.name
							loadout.data?.data = character.loadout
						}
						else {
							let loadout = NCLoadout(entity: NSEntityDescription.entity(forEntityName: "Loadout", in: managedObjectContext)!, insertInto: managedObjectContext)
							loadout.data = NCLoadoutData(entity: NSEntityDescription.entity(forEntityName: "LoadoutData", in: managedObjectContext)!, insertInto: managedObjectContext)
							loadout.typeID = Int32(ship.typeID)
							loadout.name = ship.name
							loadout.data?.data = character.loadout
						}
					}
				}
				
				if managedObjectContext.hasChanges {
					try? managedObjectContext.save()
				}

			}
			
			_ = self?.navigationController?.popViewController(animated: true)
		}))

		controller.addAction(UIAlertAction(title: NSLocalizedString("Discard and Exit", comment: ""), style: .default, handler: {[weak self] _ in
			_ = self?.navigationController?.popViewController(animated: true)
		}))
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
			
		}))

		present(controller, animated: true, completion: nil)

	}
	
	lazy var typePickerViewController: NCTypePickerViewController? = {
		return self.storyboard?.instantiateViewController(withIdentifier: "NCTypePickerViewController") as? NCTypePickerViewController
	}()
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCFittingActionsViewController"?:
			guard let controller = (segue.destination as? UINavigationController)?.topViewController as? NCFittingActionsViewController else {return}
			controller.fleet = fleet
		default:
			break
		}
	}
	
}
