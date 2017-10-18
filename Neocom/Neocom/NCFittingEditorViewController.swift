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

class NCFittingEditorViewController: UIViewController {
	var fleet: NCFittingFleet?
	var engine: NCFittingEngine?
	
//	@IBOutlet weak var stackView: UIStackView!
	
	private var observer: NotificationObserver?
	var isModified: Bool = false {
		didSet {
			if isModified {
				if navigationItem.leftBarButtonItem == nil {
					navigationItem.setLeftBarButton(UIBarButtonItem(title: NSLocalizedString("Back", comment: "Navigation item"), style: .plain, target: self, action: #selector(onBack(_:))), animated: true)
				}
				if navigationItem.rightBarButtonItems?.count == 1 {
					var items = [navigationItem.rightBarButtonItem!]
					items.append(self.saveButtonItem)
					navigationItem.setRightBarButtonItems(items, animated: true)
				}
			}
			else {
				if navigationItem.leftBarButtonItem != nil {
					navigationItem.leftBarButtonItem = nil
				}
				if navigationItem.rightBarButtonItems?.count == 2 {
					let items = [navigationItem.rightBarButtonItem!]
					navigationItem.setRightBarButtonItems(items, animated: true)
				}
			}
		}
	}
	
	lazy private var saveButtonItem: UIBarButtonItem = {
		return UIBarButtonItem(title: NSLocalizedString("Save", comment: "Navigation item"), style: .done, target: self, action: #selector(onSave(_:)))
	}()
	
	var pageViewController: NCFittingEditorPageViewController? {
		return editSplitViewController?.childViewControllers.first {$0 is NCFittingEditorPageViewController} as? NCFittingEditorPageViewController
	}
	
	var statsViewController: UIViewController!
	var editSplitViewController: UISplitViewController? {
		return childViewControllers.first {$0 is UISplitViewController} as? UISplitViewController
	}
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		navigationItem.titleView = NCNavigationItemTitleLabel(frame: CGRect(origin: .zero, size: .zero))
		
		let pilot = fleet?.active
		var useFighters = false
		var isShip = true
		engine?.performBlockAndWait {
			if let ship = pilot?.ship {
				useFighters = ship.totalFighterLaunchTubes > 0
				isShip = true
			}
			else {
				useFighters = true
				isShip = false
			}
		}
		
		var controllers = [
			storyboard!.instantiateViewController(withIdentifier: "NCFittingModulesViewController"),
			storyboard!.instantiateViewController(withIdentifier: useFighters ? "NCFittingFightersViewController" : "NCFittingDronesViewController")
		]
		
		if isShip {
			controllers.append(storyboard!.instantiateViewController(withIdentifier: "NCFittingImplantsViewController"))
			controllers.append(storyboard!.instantiateViewController(withIdentifier: "NCFittingFleetViewController"))
		}
		
		statsViewController = storyboard!.instantiateViewController(withIdentifier: "NCFittingStatsViewController")
		
		if traitCollection.horizontalSizeClass == .regular {
			editSplitViewController?.viewControllers.append(statsViewController)
		}
		else {
			controllers.append(statsViewController!)
		}
		pageViewController?.viewControllers = controllers
		
		editSplitViewController?.preferredDisplayMode = .allVisible
		editSplitViewController?.preferredPrimaryColumnWidthFraction = 0.5
		editSplitViewController?.maximumPrimaryColumnWidth = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) / 2.0

		
		updateTitle()
		

	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if observer == nil {
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
				self?.isModified = true
				self?.updateTitle()
			}
		}
		if fleet?.pilots.first(where: {$0.1 == nil}) != nil {
			var items = [navigationItem.rightBarButtonItem!]
			items.append(self.saveButtonItem)
			navigationItem.setRightBarButtonItems(items, animated: true)
		}
	}

//	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//		super.traitCollectionDidChange(previousTraitCollection)
//	}
//	
	override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
		defer {super.willTransition(to: newCollection, with: coordinator)}
		guard newCollection.horizontalSizeClass != traitCollection.horizontalSizeClass && newCollection.userInterfaceIdiom == .pad else {return}
//		guard previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass else {return}
		guard let statsViewController = statsViewController else {return}

//		switch traitCollection.horizontalSizeClass {
		switch newCollection.horizontalSizeClass {
		case .regular:
			guard editSplitViewController?.viewControllers.count == 1 else {return}
			
			statsViewController.willMove(toParentViewController: nil)
			statsViewController.view.removeFromSuperview()
			pageViewController?.viewControllers?.removeLast()
			statsViewController.removeFromParentViewController()
			
			editSplitViewController?.viewControllers.append(statsViewController)
		default:
			guard editSplitViewController?.viewControllers.count == 2 else {return}

			statsViewController.willMove(toParentViewController: nil)
			editSplitViewController?.viewControllers.removeLast()
			statsViewController.removeFromParentViewController()

			pageViewController?.viewControllers?.append(statsViewController)
		}
	}
	
	
	@IBAction func onActions(_ sender: UIBarButtonItem) {
		guard let fleet = self.fleet else {return}
		Router.Fitting.Actions(fleet: fleet).perform(source: self, sender: sender)
	}
	
	func save(completionHandler: (() -> Void)? = nil) {
		guard let fleet = fleet, let engine = self.engine else {
			completionHandler?()
			return
		}
		
		NCStorage.sharedStorage?.performBackgroundTask {managedObjectContext in
			engine.performBlockAndWait {
				var pilots = [String: NCLoadout] ()
				for (character, objectID) in fleet.pilots {
					
					if character.identifier == nil {
						character.identifier = UUID().uuidString
					}
					
					guard let ship = character.ship ?? character.structure else {continue}
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
				
				var opaqueFleet: NCFleet?
				
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
					opaqueFleet = object
				}
				
				if managedObjectContext.hasChanges {
					try? managedObjectContext.save()
				}
				
				fleet.pilots = fleet.pilots.map {($0.0, pilots[$0.0.identifier!]?.objectID)}
				fleet.fleetID = opaqueFleet?.objectID
			}
			DispatchQueue.main.async {
				self.isModified = false
				completionHandler?()
			}
		}
	}
	
	@objc private func onBack(_ sender: Any) {
		let controller = UIAlertController(title: nil, message: NSLocalizedString("Save Changes?", comment: ""), preferredStyle: .alert)
		controller.addAction(UIAlertAction(title: NSLocalizedString("Save and Exit", comment: ""), style: .default, handler: {[weak self] _ in
			self?.save {
				_ = self?.navigationController?.popViewController(animated: true)
			}
			
		}))

		controller.addAction(UIAlertAction(title: NSLocalizedString("Discard and Exit", comment: ""), style: .default, handler: {[weak self] _ in
			_ = self?.navigationController?.popViewController(animated: true)
		}))
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
			
		}))

		present(controller, animated: true, completion: nil)

	}
	
	@objc private func onSave(_ sender: Any) {
		save()
	}
	
	lazy var typePickerViewController: NCTypePickerViewController? = {
		guard let controller =  UIStoryboard.database.instantiateViewController(withIdentifier: "NCTypePickerViewController") as? NCTypePickerViewController else {return nil}
		NCSlideDownDismissalInteractiveTransitioning.add(to: controller)
		
		return controller
//		return self.storyboard?.instantiateViewController(withIdentifier: "NCTypePickerViewController") as? NCTypePickerViewController
	}()
	
	private func updateTitle() {
		guard let titleLabel = navigationItem.titleView as? NCNavigationItemTitleLabel else {return}
		let pilot = fleet?.active
		var shipName: String = ""
		var typeName: String = ""
		
		engine?.performBlockAndWait {
			guard let ship = pilot?.ship ?? pilot?.structure else {return}
			shipName = ship.name
			typeName = NCDatabase.sharedDatabase?.invTypes[ship.typeID]?.typeName ?? ""
		}
//		titleLabel.attributedText = typeName * [:] + (!shipName.isEmpty ? "\n" + shipName * [NSAttributedStringKey.font:UIFont.preferredFont(forTextStyle: .footnote), NSAttributedStringKey.foregroundColor: UIColor.lightText] : "" * [:])
//		titleLabel.sizeToFit()
		titleLabel.set(title: typeName, subtitle: shipName)
	}

}


protocol NCFittingEditorPage {
	
}

extension NCFittingEditorPage where Self: UIViewController {
	
	var editorViewController: NCFittingEditorViewController? {
		return sequence(first: parent, next: {$0?.parent}).first {$0 is NCFittingEditorViewController} as? NCFittingEditorViewController
	}
	
	var engine: NCFittingEngine? {
		return editorViewController?.engine
	}
	
	var fleet: NCFittingFleet? {
		return editorViewController?.fleet
	}
	
	var typePickerViewController: NCTypePickerViewController? {
		return editorViewController?.typePickerViewController
	}

}
