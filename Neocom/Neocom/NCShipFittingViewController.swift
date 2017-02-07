//
//  NCShipFittingViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCShipFittingViewController: UIViewController {
	var fleet: NCFleet?
	var engine: NCFittingEngine?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		engine = NCFittingEngine()
		engine?.performBlockAndWait {
			self.fleet = NCFleet(typeID: 645, engine: self.engine!)
			let pilot = self.fleet?.active
			for skill in pilot?.skills.all ?? [] {
				skill.level = 5
			}
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
	}
	
	lazy var typePickerViewController: NCTypePickerViewController? = {
		return self.storyboard?.instantiateViewController(withIdentifier: "NCTypePickerViewController") as? NCTypePickerViewController
	}()
	
}
