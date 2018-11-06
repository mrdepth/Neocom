//
//  WhTypesPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class WhTypesPresenter: TreePresenter {
	typealias View = WhTypesViewController
	typealias Interactor = WhTypesInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.NamedFetchedResultsSection<Tree.Item.FetchedResultsRow<SDEWhType>>>
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeSectionCell.default,
								  Prototype.TreeDefaultCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		
		let filter: Predictable
		
		if view?.parent is UISearchController, let searchString = searchManager.pop() {
			filter = searchString.isEmpty ? false : (\SDEWhType.type?.typeName).contains(searchString)
		}
		else {
			filter = true
		}
		
		let frc = Services.sde.viewContext.managedObjectContext
			.from(SDEWhType.self)
			.filter(filter)
			.sort(by: \SDEWhType.targetSystemClass, ascending: true)
			.sort(by: \SDEWhType.type?.typeName, ascending: true)
			.fetchedResultsController(sectionName: \SDEWhType.targetSystemClassDisplayName, cacheName: nil)
		
		return .init(Presentation(frc, treeController: view?.treeController))
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEWhType>, let type = item.result.type, let view = view else {return}
		
		Router.SDE.invTypeInfo(.type(type)).perform(from: view)
	}
	
	private lazy var searchManager = SearchManager(presenter: self)
	
	func updateSearchResults(with string: String) {
		searchManager.updateSearchResults(with: string)
	}

}

extension SDEWhType: CellConfiguring {
	var prototype: Prototype? {
		return Prototype.TreeDefaultCell.default
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeDefaultCell else {return}
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
		cell.accessoryType = .disclosureIndicator
		if maxStableMass > 0 {
			cell.subtitleLabel?.isHidden = false
			cell.subtitleLabel?.text = "\(UnitFormatter.localizedString(from: maxJumpMass, unit: .none, style: .long))/\(UnitFormatter.localizedString(from: maxStableMass, unit: .kilogram, style: .long))"
		}
		else {
			cell.subtitleLabel?.isHidden = true
			cell.subtitleLabel?.text = nil
		}
	}
}
