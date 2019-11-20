//
//  MapLocationPickerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class MapLocationPickerViewController: NavigationController, View {
	enum Location {
		case solarSystem(SDEMapSolarSystem)
		case region(SDEMapRegion)
	}
	
	struct Mode: OptionSet {
		let rawValue: Int
		
		static let regions = Mode(rawValue: 1 << 0)
		static let solarSystems = Mode(rawValue: 1 << 1)
		
		static let all: Mode = [.regions, .solarSystems]
	}
	
	struct Input {
		let mode: Mode
		let completion: (MapLocationPickerViewController, MapLocationPickerViewController.Location) -> Void
	}
	
	typealias Presenter = MapLocationPickerPresenter
	lazy var presenter: Presenter! = Presenter(view: self)
	var unwinder: Unwinder?
	var input: Input?

	override func viewDidLoad() {
		super.viewDidLoad()
		presenter.configure()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		presenter.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presenter.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		presenter.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		presenter.viewDidDisappear(animated)
	}
}


class MapLocationPickerPageViewController: PageViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		guard let controller = parent as? MapLocationPickerViewController else {return}
		guard let input = controller.input else {return}
		
		try! viewControllers = [MapLocationPickerRegions.default.instantiate(input.mode).get(),
								MapLocationPickerRecents.default.instantiate(input.mode).get()]
	}
}
