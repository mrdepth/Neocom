//
//  NCShipFittingViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCShipFittingViewController: UIViewController {
	var fleet: NCFittingFleet?
	var engine: NCFittingEngine?
	
	private var observer: NSObjectProtocol?
	private var isModified: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		engine = NCFittingEngine()
		engine?.performBlockAndWait {
			self.fleet = NCFittingFleet(typeID: 645, engine: self.engine!)
			let pilot = self.fleet?.active
			//pilot?.skills.setAllSkillsLevel(5)
			pilot?.setSkills(level: 5)
			let ship = pilot?.ship
			for _ in 0..<3 {
				let module = ship?.addModule(typeID: 3130)
				module?.charge = NCFittingCharge(typeID: 230)
				//module?.preferredState = .overloaded
			}
			for _ in 0..<5 {
				_ = ship?.addDrone(typeID: 2446)
			}
		}
		
		observer = NotificationCenter.default.addObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
			self?.isModified = true
		}

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
