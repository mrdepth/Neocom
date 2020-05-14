//
//  DgmTypePickerRecentsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 25/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class DgmTypePickerRecentsPresenter: TreePresenter {
	typealias View = DgmTypePickerRecentsViewController
	typealias Interactor = DgmTypePickerRecentsInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsSection<Tree.Item.TypePickerRecentRow>>

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
								  Prototype.InvTypeCell.charge,
								  Prototype.InvTypeCell.default,
								  Prototype.InvTypeCell.module,
								  Prototype.InvTypeCell.ship])

		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let input = view?.input else {return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		let frc = Services.cache.viewContext.managedObjectContext
			.from(TypePickerRecent.self)
			.filter(\TypePickerRecent.category == input.category &&
				\TypePickerRecent.subcategory == input.subcategory &&
				\TypePickerRecent.raceID == input.race?.raceID ?? 0)
			.sort(by: \TypePickerRecent.date, ascending: false)
			.fetchedResultsController()
		
		return .init(Presentation(frc, treeController: view?.treeController))
	}
}

extension Tree.Item {
	class TypePickerRecentRow: FetchedResultsRow<TypePickerRecent> {
		lazy var type = Services.sde.viewContext.invType(Int(result.typeID))
		
		override var prototype: Prototype? {
			let item = type?.dgmppItem
			return item?.shipResources?.prototype ??
				item?.requirements?.prototype ??
				item?.damage?.prototype ??
				type?.prototype
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			let item = type?.dgmppItem
			item?.shipResources?.configure(cell: cell, treeController: treeController) ??
				item?.requirements?.configure(cell: cell, treeController: treeController) ??
				item?.damage?.configure(cell: cell, treeController: treeController) ??
				type?.configure(cell: cell, treeController: treeController)
		}
	}
}

