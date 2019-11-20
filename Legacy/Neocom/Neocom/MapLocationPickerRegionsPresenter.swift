//
//  MapLocationPickerRegionsPresenter.swift
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

class MapLocationPickerRegionsPresenter: TreePresenter {
	typealias View = MapLocationPickerRegionsViewController
	typealias Interactor = MapLocationPickerRegionsInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.NamedFetchedResultsSection<Tree.Item.FetchedResultsRow<SDEMapRegion>>>
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeDefaultCell.default,
								  Prototype.TreeSectionCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let controller = Services.sde.viewContext.managedObjectContext
			.from(SDEMapRegion.self)
			.sort(by: \SDEMapRegion.securityClass, ascending: true)
			.sort(by: \SDEMapRegion.regionName, ascending: true)
			.fetchedResultsController(sectionName: \SDEMapRegion.securityClassDisplayName, cacheName: nil)
		
		return .init(Presentation(controller, treeController: view?.treeController))
	}
	
	func didSelect(_ region: SDEMapRegion) {
		guard let controller = view?.navigationController as? MapLocationPickerViewController else {return}
		controller.input?.completion(controller, .region(region))
	}
	
	func didOpen(_ region: SDEMapRegion) {
		guard let view = view else {return}
		Router.SDE.mapLocationPickerSolarSystems(region).perform(from: view)
	}

}

extension SDEMapRegion: CellConfigurable {
	var prototype: Prototype? {
		return Prototype.TreeDefaultCell.default
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeDefaultCell else {return}
		cell.titleLabel?.text = regionName
		cell.subtitleLabel?.isHidden = true
		cell.iconView?.isHidden = true
	}
}
