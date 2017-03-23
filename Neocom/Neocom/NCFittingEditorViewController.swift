//
//  NCFittingEditorViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import CloudData

class NCFittingEditorViewController: NCPageViewController {
	var fleet: NCFittingFleet?
	var engine: NCFittingEngine?
	
	private var observer: NotificationObserver?
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
		let titleLabel = UILabel(frame: CGRect(origin: .zero, size: .zero))
		titleLabel.numberOfLines = 2
		titleLabel.textAlignment = .center
		titleLabel.textColor = .white
		titleLabel.minimumScaleFactor = 0.5
		titleLabel.font = navigationController?.navigationBar.titleTextAttributes?[NSFontAttributeName] as? UIFont ?? UIFont.systemFont(ofSize: 17)
		navigationItem.titleView = titleLabel
		
		let pilot = fleet?.active
		var useFighters = false
		engine?.performBlockAndWait {
			guard let ship = pilot?.ship else {return}
			useFighters = ship.totalFighterLaunchTubes > 0
		}
		
		viewControllers = [
			storyboard!.instantiateViewController(withIdentifier: "NCFittingModulesViewController"),
			storyboard!.instantiateViewController(withIdentifier: useFighters ? "NCFittingFightersViewController" : "NCFittingDronesViewController"),
			storyboard!.instantiateViewController(withIdentifier: "NCFittingImplantsViewController"),
			storyboard!.instantiateViewController(withIdentifier: "NCFittingFleetViewController"),
			storyboard!.instantiateViewController(withIdentifier: "NCFittingStatsViewController"),
		]
		
		updateTitle()
		
		observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
			self?.isModified = true
			self?.updateTitle()
		}

	}
	
	@objc private func onBack(_ sender: Any) {
		let controller = UIAlertController(title: nil, message: NSLocalizedString("Save Changes?", comment: ""), preferredStyle: .alert)
		controller.addAction(UIAlertAction(title: NSLocalizedString("Save and Exit", comment: ""), style: .default, handler: {[weak self] _ in
			guard let fleet = self?.fleet else {return}
			
			NCStorage.sharedStorage?.performBackgroundTask {managedObjectContext in
				self?.engine?.performBlockAndWait {
					var pilots = [String: NCLoadout] ()
					for (character, objectID) in fleet.pilots {
						
						if character.identifier == nil {
							character.identifier = UUID().uuidString
						}
						
						guard let ship = character.ship else {continue}
						if let objectID = objectID, let loadout = (try? managedObjectContext.existingObject(with: objectID)) as? NCLoadout {
							loadout.uuid = character.identifier
							loadout.name = ship.name
							loadout.data?.data = character.loadout
							pilots[loadout.uuid!] = loadout
						}
						else {
							let loadout = NCLoadout(entity: NSEntityDescription.entity(forEntityName: "Loadout", in: managedObjectContext)!, insertInto: managedObjectContext)
							loadout.data = NCLoadoutData(entity: NSEntityDescription.entity(forEntityName: "LoadoutData", in: managedObjectContext)!, insertInto: managedObjectContext)
							loadout.typeID = Int32(ship.typeID)
							loadout.name = ship.name
							loadout.data?.data = character.loadout
							loadout.uuid = character.identifier
							pilots[loadout.uuid!] = loadout
						}
					}
					
					if fleet.pilots.count > 1 {
						let object: NCFleet
						if let fleetID = fleet.fleetID, let fleet = (try? managedObjectContext.existingObject(with: fleetID)) as? NCFleet {
							if (fleet.loadouts?.count ?? 0) > 0 {
								fleet.removeFromLoadouts(fleet.loadouts!)
							}
							object = fleet
						}
						else {
							object = NCFleet(entity: NSEntityDescription.entity(forEntityName: "Fleet", in: managedObjectContext)!, insertInto: managedObjectContext)
							object.name = NSLocalizedString("Fleet", comment: "")
						}
						
						for (character, _) in fleet.pilots {
							guard let pilot = pilots[character.identifier!] else {continue}
							pilot.addToFleets(object)
						}
						object.configuration = fleet.configuration
					}
				}
				
//				if managedObjectContext.hasChanges {
//					try? managedObjectContext.save()
//				}

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
	
	
	
	private func updateTitle() {
		guard let titleLabel = navigationItem.titleView as? UILabel else {return}
		let pilot = fleet?.active
		var shipName: String = ""
		var typeName: String = ""
		
		engine?.performBlockAndWait {
			guard let ship = pilot?.ship else {return}
			shipName = ship.name
			typeName = NCDatabase.sharedDatabase?.invTypes[ship.typeID]?.typeName ?? ""
		}
		titleLabel.attributedText = typeName * [:] + (!shipName.isEmpty ? "\n" + shipName * [NSFontAttributeName:UIFont.preferredFont(forTextStyle: .footnote), NSForegroundColorAttributeName: UIColor.lightText] : "" * [:])
		titleLabel.sizeToFit()
	}

}
