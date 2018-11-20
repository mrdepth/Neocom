//
//  ContactsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/20/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class ContactsPresenter: TreePresenter {
	typealias View = ContactsViewController
	typealias Interactor = ContactsInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsSection<Tree.Item.ContactFetchedResultsRow>>
	
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
								  Prototype.TreeDefaultCell.default,
								  Prototype.TreeDefaultCell.contact])

		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let frc = Services.cache.viewContext.managedObjectContext
			.from(Contact.self)
			.filter(\Contact.lastUse != nil)
			.sort(by: \Contact.lastUse, ascending: false)
			.fetchedResultsController()
		
		return .init(Presentation(frc, treeController: view?.treeController))
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.ContactFetchedResultsRow else {return}
		didSelectContact(item.result)
	}

	
	func didSelectContact(_ contact: Contact) {
		guard let view = view else {return}
		contact.lastUse = Date()
		try? Services.cache.viewContext.save()
		view.input?.completion(view, contact)
	}
}

extension Tree.Item {
	class ContactFetchedResultsRow: FetchedResultsRow<Contact> {
		var image: UIImage?
		
		override var prototype: Prototype? {
			return result.recipientType == .character ? Prototype.TreeDefaultCell.contact : Prototype.TreeDefaultCell.default
		}
		
		lazy var api = Services.api.current
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? TreeDefaultCell else {return}
			cell.titleLabel?.text = result.name
			cell.subtitleLabel?.text = result.recipientType?.title
			cell.iconView?.isHidden = false
			cell.iconView?.image = image ?? UIImage()
			
			if image == nil {
				let dimension = Int(cell.iconView!.bounds.width)
				
				api.image(contact: result, dimension: dimension, cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self, weak treeController] result in
					guard let strongSelf = self else {return}
					strongSelf.image = result.value
					treeController?.reloadRow(for: strongSelf, with: .none)
				}.catch(on: .main) { [weak self] _ in
					self?.image = UIImage()
				}
			}

		}
	}
}
