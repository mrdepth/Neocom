//
//  InvCategoriesPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import Expressible
import CoreData
import TreeController

class InvCategoriesPresenter: TreePresenter {
	typealias View = InvCategoriesViewController
	typealias Interactor = InvCategoriesInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.InvPublishedSection<Tree.Item.FetchedResultsRow<SDEInvCategory>>>
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeDefaultCell.default, Prototype.TreeHeaderCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let controller = Services.sde.viewContext.managedObjectContext
			.from(SDEInvCategory.self)
			.sort(by: \SDEInvCategory.published, ascending: false)
			.sort(by: \SDEInvCategory.categoryName, ascending: true)
			.fetchedResultsController(sectionName: \SDEInvCategory.published)
		
		let result = Presentation(controller, treeController: view?.treeController)
		return .init(result)
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEInvCategory> else {return}
		guard let view = view else {return}
		Router.SDE.invGroups(.category(item.result)).perform(from: view)
	}
	
}

extension Tree.Item {
	
	class InvPublishedSection<Item: FetchedResultsTreeItem>: NamedFetchedResultsSection<Item> {
		
		override var name: String {
			return (sectionInfo.name == "0" ? NSLocalizedString("Unpublished", comment: "") : NSLocalizedString("Published", comment: "")).uppercased()
		}
	}
}

extension SDEInvCategory: CellConfiguring {
	var prototype: Prototype? {
		return Prototype.TreeDefaultCell.default
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeDefaultCell else {return}
		cell.titleLabel?.text = categoryName
		cell.subtitleLabel?.isHidden = true
		cell.iconView?.image = icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultCategory)?.image?.image
		cell.accessoryType = .disclosureIndicator
	}
}
