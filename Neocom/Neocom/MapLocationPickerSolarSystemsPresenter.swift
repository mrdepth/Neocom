//
//  MapLocationPickerSolarSystemsPresenter.swift
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

class MapLocationPickerSolarSystemsPresenter: TreePresenter {
	typealias View = MapLocationPickerSolarSystemsViewController
	typealias Interactor = MapLocationPickerSolarSystemsInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsSection<Tree.Item.FetchedResultsRow<SDEMapSolarSystem>>>

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

		let controller = Services.sde.viewContext.managedObjectContext
			.from(SDEMapSolarSystem.self)
			.filter(\SDEMapSolarSystem.constellation?.region == input)
			.sort(by: \SDEMapSolarSystem.solarSystemName, ascending: true)
			.fetchedResultsController(sectionName: nil, cacheName: nil)
		
		return .init(Presentation(controller, treeController: view?.treeController))
	}
	
	func didSelect(_ solarSystem: SDEMapSolarSystem) {
		guard let controller = view?.navigationController as? MapLocationPickerViewController else {return}
		controller.input?.completion(controller, .solarSystem(solarSystem))
	}

}

extension SDEMapSolarSystem: CellConfiguring {
	var prototype: Prototype? {
		return Prototype.TreeDefaultCell.default
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeDefaultCell else {return}
		cell.titleLabel?.text = solarSystemName
		cell.subtitleLabel?.isHidden = true
		cell.iconView?.isHidden = true
	}
}
