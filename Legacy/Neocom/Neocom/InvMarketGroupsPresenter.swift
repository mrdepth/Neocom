//
//  InvMarketGroupsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class InvMarketGroupsPresenter: TreePresenter {
	typealias View = InvMarketGroupsViewController
	typealias Interactor = InvMarketGroupsInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsSection<Tree.Item.FetchedResultsRow<SDEInvMarketGroup>>>

	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeDefaultCell.default, Prototype.TreeSectionCell.default])
		
		if let title = view?.input?.marketGroupName {
			view?.title = title
		}

		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let parent = view?.input
		let frc = Services.sde.viewContext.managedObjectContext
			.from(SDEInvMarketGroup.self)
			.sort(by: \SDEInvMarketGroup.marketGroupName, ascending: true)
			.filter(\SDEInvMarketGroup.parentGroup == parent)
			.fetchedResultsController()
		return .init(Presentation(frc, treeController: view?.treeController))
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEInvMarketGroup> else {return}
		guard let view = view else {return}
		if (item.result.types?.count ?? 0) > 0 {
			Router.SDE.invTypes(.marketGroup(item.result)).perform(from: view)
		}
		else {
			Router.SDE.invMarketGroups(item.result).perform(from: view)
		}
//		Router.SDE.invTypes(<#T##input: InvTypes.View.Input##InvTypes.View.Input#>)
	}

}

extension SDEInvMarketGroup: CellConfigurable {
	var prototype: Prototype? {
		return Prototype.TreeDefaultCell.default
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeDefaultCell else {return}
		cell.titleLabel?.text = marketGroupName
		cell.subtitleLabel?.isHidden = true
		cell.iconView?.image = icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultGroup)?.image?.image
		cell.accessoryType = .disclosureIndicator
	}
}
