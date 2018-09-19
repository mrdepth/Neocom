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

class InvCategoriesPresenter: TreePresenter {
	typealias View = InvCategoriesViewController
	typealias Interactor = InvCategoriesInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.InvPublishedSection<Tree.Item.FetchedResultsRow<SDEInvCategory>>>
	
	weak var view: View!
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view.tableView.register([Prototype.TreeDefaultCell.default, Prototype.TreeHeaderCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let request = Services.sde.viewContext.managedObjectContext.from(SDEInvCategory.self).sort(by: \SDEInvCategory.published, ascending: false).sort(by: \SDEInvCategory.categoryName, ascending: true).fetchRequest
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: Services.sde.viewContext.managedObjectContext, sectionNameKeyPath: "published", cacheName: nil)
		
		let result = Presentation(controller, treeController: view.treeController)
		return .init(result)
	}
}

extension Tree.Item {
	
	class InvPublishedSection<Item: FetchedResultsTreeItem>: FetchedResultsSection<Item>, CellConfiguring, ExpandableItem {
		
		var isExpanded: Bool = true {
			didSet {
				controller?.treeController?.reloadRow(for: self, with: .none)
			}
		}
		
		var prototype: Prototype? {
			return Prototype.TreeHeaderCell.default
		}
		
		var expandIdentifier: CustomStringConvertible?
		
		func configure(cell: UITableViewCell) {
			guard let cell = cell as? TreeHeaderCell else {return}
			
			cell.titleLabel?.text = (sectionInfo.name == "0" ? NSLocalizedString("Unpublished", comment: "") : NSLocalizedString("Published", comment: "")).uppercased()
			cell.expandIconView?.image = isExpanded ? #imageLiteral(resourceName: "collapse") : #imageLiteral(resourceName: "expand")
		}
	}
}

extension SDEInvCategory: CellConfiguring {
	var prototype: Prototype? {
		return Prototype.TreeDefaultCell.default
	}
	
	func configure(cell: UITableViewCell) {
		guard let cell = cell as? TreeDefaultCell else {return}
		cell.titleLabel?.text = categoryName
		cell.subtitleLabel?.isHidden = true
		cell.iconView?.image = icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultCategory)?.image?.image
	}
	
}
