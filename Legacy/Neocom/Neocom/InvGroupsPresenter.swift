//
//  InvGroupsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import CoreData
import Expressible
import TreeController

class InvGroupsPresenter: TreePresenter {
	typealias View = InvGroupsViewController
	typealias Interactor = InvGroupsInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.InvPublishedSection<Tree.Item.FetchedResultsRow<SDEInvGroup>>>
	
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
		
		switch view?.input {
		case let .category(category)?:
			view?.title = category.categoryName
		default:
			break
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let input = view?.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		var request = Services.sde.viewContext.managedObjectContext
			.from(SDEInvGroup.self)
			.sort(by: \SDEInvGroup.published, ascending: false)
			.sort(by: \SDEInvGroup.groupName, ascending: true)
		
		switch input {
		case let .category(category):
			request = request.filter(\SDEInvGroup.category == category)
		}
		
		let controller = request.fetchedResultsController(sectionName: \SDEInvGroup.published)
		
		let result = Presentation(controller, treeController: view?.treeController)
		return .init(result)
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEInvGroup>, let view = view else {return}
		Router.SDE.invTypes(.group(item.result)).perform(from: view)
	}

}

extension SDEInvGroup: CellConfigurable {
	var prototype: Prototype? {
		return Prototype.TreeDefaultCell.default
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeDefaultCell else {return}
		cell.titleLabel?.text = groupName
		cell.subtitleLabel?.isHidden = true
		cell.iconView?.image = icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultGroup)?.image?.image
		cell.accessoryType = .disclosureIndicator
	}
}
