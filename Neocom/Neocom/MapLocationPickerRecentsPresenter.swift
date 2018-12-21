//
//  MapLocationPickerRecentsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures
import CloudData
import Expressible

class MapLocationPickerRecentsPresenter: TreePresenter {
	typealias View = MapLocationPickerRecentsViewController
	typealias Interactor = MapLocationPickerRecentsInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsSection<Tree.Item.FetchedResultsRow<LocationPickerRecent>>>

	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeDefaultCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let input = view?.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		let controller = Services.cache.viewContext.managedObjectContext
			.from(LocationPickerRecent.self)
			.filter(\LocationPickerRecent.locationType & Int32(input.rawValue) > 0 )
			.sort(by: \LocationPickerRecent.date, ascending: false)
			.fetchedResultsController(sectionName: nil, cacheName: nil)
		
		return .init(Presentation(controller, treeController: view?.treeController))
	}
}

extension LocationPickerRecent: CellConfigurable {
	var prototype: Prototype? {
		return Prototype.TreeDefaultCell.default
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeDefaultCell else {return}
		switch Int(locationType) {
		case MapLocationPickerViewController.Mode.regions.rawValue:
			let region = Services.sde.viewContext.mapRegion(Int(locationID))
			cell.titleLabel?.text = region?.regionName ?? NSLocalizedString("Unknown Location", comment: "")
		case MapLocationPickerViewController.Mode.solarSystems.rawValue:
			let solarSystem = Services.sde.viewContext.mapSolarSystem(Int(locationID))
			cell.titleLabel?.text = solarSystem?.solarSystemName ?? NSLocalizedString("Unknown Location", comment: "")
		default:
			cell.titleLabel?.text = NSLocalizedString("Unknown Location", comment: "")
		}
		cell.subtitleLabel?.isHidden = true
		cell.iconView?.isHidden = true
	}
	
	
}
