//
//  ContactsSearchResultsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import EVEAPI

class ContactsSearchResultsPresenter: TreePresenter {
	typealias View = ContactsSearchResultsViewController
	typealias Interactor = ContactsSearchResultsInteractor
	typealias Presentation = [Tree.Item.Section<Tree.Item.ContactRow>]
	
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
		let api = interactor.api
		
		let groups = Dictionary(grouping: content.map {Tree.Item.ContactRow($0, api: api)}, by: {$0.content.recipientType})
		
		var sections = Presentation()
		
		if let rows = groups[.character] {
			sections.append(Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Characters", comment: "").uppercased()),
											  diffIdentifier: "Characters",
											  treeController: view?.treeController,
											  children: rows))
		}
		if let rows = groups[.corporation] {
			sections.append(Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Corporations", comment: "").uppercased()),
											  diffIdentifier: "Corporations",
											  treeController: view?.treeController,
											  children: rows))
		}
		if let rows = groups[.alliance] {
			sections.append(Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Alliances", comment: "").uppercased()),
											  diffIdentifier: "Alliances",
											  treeController: view?.treeController,
											  children: rows))
		}

		return .init(sections)
	}
	
	
	lazy var searchManager = SearchManager(presenter: self)
	
	func updateSearchResults(with string: String?) {
		searchManager.updateSearchResults(with: string ?? "")
	}

	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.ContactRow else { return }
		guard let strongView = view else {return}
		view?.input?.contactsSearchResultsViewController(strongView, didSelect: item.content)
	}
}

extension Tree.Item {
	class ContactRow: Row<Contact> {
		var api: API
		
		init(_ content: Contact, api: API) {
			self.api = api
			super.init(content)
		}
		
		override var prototype: Prototype? {
			return content.recipientType == .character ? Prototype.TreeDefaultCell.contact : Prototype.TreeDefaultCell.default
		}
		
		var image: UIImage?
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? TreeDefaultCell else {return}
			cell.titleLabel?.text = content.name
			cell.subtitleLabel?.isHidden = true
			cell.iconView?.isHidden = false
			cell.iconView?.image = image ?? UIImage()
			
			if image == nil {
				let image: Future<ESI.Result<UIImage>>?
				let dimension = Int(cell.iconView!.bounds.width)
				
				switch content.recipientType {
				case .character?:
					image = api.image(characterID: content.contactID, dimension: dimension, cachePolicy: .useProtocolCachePolicy)
				case .corporation?:
					image = api.image(corporationID: content.contactID, dimension: dimension, cachePolicy: .useProtocolCachePolicy)
				case .alliance?:
					image = api.image(allianceID: content.contactID, dimension: dimension, cachePolicy: .useProtocolCachePolicy)
				default:
					image = nil
				}
				
				image?.then(on: .main) { [weak self, weak treeController] result in
					guard let strongSelf = self else {return}
					strongSelf.image = result.value
					treeController?.reloadRow(for: strongSelf, with: .none)
				}
			}
		}
	}
}

