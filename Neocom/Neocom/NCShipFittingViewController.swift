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
		let d = DispatchGroup()
		d.enter()
		engine?.perform {
			self.fleet = NCFleet(typeID: 645, engine: self.engine!)
			let ship = self.fleet?.active?.ship
			let module = ship?.addModule(typeID: 3130)
			module?.charge = NCFittingCharge(typeID: 230)
			d.leave()
		}
		d.wait()
	}
	
	lazy var typePickerViewController: NCTypePickerViewController? = {
		return self.storyboard?.instantiateViewController(withIdentifier: "NCTypePickerViewController") as? NCTypePickerViewController
	}()
}
