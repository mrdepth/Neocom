//
//  FittingLoadoutsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/23/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible
import CoreData

class FittingLoadoutsPresenter: TreePresenter {
	typealias View = FittingLoadoutsViewController
	typealias Interactor = FittingLoadoutsInteractor
	typealias Presentation = [AnyTreeItem]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeSectionCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		
		Services.storage.performBackgroundTask { context in

			let loadouts = try context.managedObjectContext
				.from(Loadout.self)
				.select((\Loadout.typeID, Self.as(NSManagedObjectID.self, name: "objectID")))
				.all()
				.filter {$0.0 != nil && $0.1 != nil}
//				.filter{$0.typeID != nil && $0.objectID != nil}
			
			Services.sde.performBackgroundTask { context in
				let items = loadouts.compactMap { i in context.invType(Int(i.0!)).map {(typeID: i.0!, loadout: i.1!, type: $0)} }
				let groups = Dictionary(grouping: items) {$0.type.group}.sorted {$0.key?.groupName ?? "" < $1.key?.groupName ?? ""}
				
				groups.map { i in
				}
			}
		}
		
		return .init([])
	}
}

extension Tree.Item {
	class LoadoutRow: Row<Loadout> {
	}
}
