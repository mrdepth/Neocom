//
//  NpcGroupsPresenter.swift
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

class NpcGroupsPresenter: TreePresenter {
	typealias View = NpcGroupsViewController
	typealias Interactor = NpcGroupsInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsSection<Tree.Item.FetchedResultsRow<SDENpcGroup>>>

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
		
		switch view?.input {
		case let .parent(npcGroup)?:
			view?.title = npcGroup.npcGroupName
		default:
			break
		}
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let parent: SDENpcGroup?
		if case let .parent(npcGroup)? = view?.input {
			parent = npcGroup
		}
		else {
			parent = nil
		}
		
		let frc = Services.sde.viewContext.managedObjectContext
			.from(SDENpcGroup.self)
			.sort(by: \SDENpcGroup.npcGroupName, ascending: true)
			.filter(\SDENpcGroup.parentNpcGroup == parent)
			.fetchedResultsController()
		return .init(Presentation(frc, treeController: view?.treeController))
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDENpcGroup> else {return}
		guard let view = view else {return}
		if item.result.group != nil {
			Router.SDE.invTypes(.npcGroup(item.result)).perform(from: view)
		}
		else {
			Router.SDE.npcGroups(.parent(item.result)).perform(from: view)
		}
	}
}

extension SDENpcGroup: CellConfiguring {
	var prototype: Prototype? {
		return Prototype.TreeDefaultCell.default
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeDefaultCell else {return}
		cell.titleLabel?.text = npcGroupName
		cell.subtitleLabel?.isHidden = true
		cell.iconView?.image = icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultGroup)?.image?.image
		cell.accessoryType = .disclosureIndicator
	}
}
