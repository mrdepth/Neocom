//
//  DgmTypePickerGroupsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 16/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class DgmTypePickerGroupsPresenter: TreePresenter {
	typealias View = DgmTypePickerGroupsViewController
	typealias Interactor = DgmTypePickerGroupsInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsSection<Tree.Item.FetchedResultsRow<SDEDgmppItemGroup>>>

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
		guard let input = view?.input else {return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		let frc = Services.sde.viewContext.managedObjectContext
			.from(SDEDgmppItemGroup.self)
			.filter(\SDEDgmppItemGroup.parentGroup == input)
			.sort(by: \SDEDgmppItemGroup.groupName, ascending: true)
			.fetchedResultsController()
		let result = Presentation(frc, treeController: view?.treeController)
		return .init(result)
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEDgmppItemGroup>, let view = view else {return}
		if (item.result.subGroups?.count ?? 0) > 0 {
			Router.Fitting.dgmTypePickerGroups(item.result).perform(from: view)
		}
		else {
			Router.Fitting.dgmTypePickerTypes(.group(item.result)).perform(from: view)
		}
	}

}

extension SDEDgmppItemGroup: CellConfigurable {
	var prototype: Prototype? {
		return Prototype.TreeDefaultCell.default
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeDefaultCell else {return}
		cell.titleLabel?.text = groupName
		cell.iconView?.image = icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultGroup)?.image?.image
		cell.subtitleLabel?.isHidden = true
		cell.accessoryType = .disclosureIndicator
	}
}
