//
//  FittingLoadoutsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/23/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import CoreData

class FittingLoadoutsInteractor: TreeInteractor {
	typealias Presenter = FittingLoadoutsPresenter
	typealias Content = Void
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	lazy var storageContext: StorageContext = Services.storage.newBackgroundContext()
	
	func configure() {
		managedObjectContextDidSaveObsever = NotificationCenter.default.addNotificationObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: nil) { [weak self] (note) in
			self?.managedObjectContextDidSave(with: note)
		}
	}
	
	private var managedObjectContextDidSaveObsever: NotificationObserver?
	func managedObjectContextDidSave(with note: Notification) {
		let storageContext = self.storageContext

		guard (note.object as? NSManagedObjectContext)?.persistentStoreCoordinator == storageContext.managedObjectContext.persistentStoreCoordinator else {return}
		storageContext.perform { [weak self] in
			storageContext.managedObjectContext.mergeChanges(fromContextDidSave: note)
			let updated: [Loadout]? = (note.userInfo?[NSUpdatedObjectsKey] as? NSSet)?.allObjects.compactMap {$0 as? Loadout}.compactMap{(try? storageContext.existingObject(with: $0.objectID)) ?? nil}
			let deleted: [Loadout]? = (note.userInfo?[NSDeletedObjectsKey] as? NSSet)?.allObjects.compactMap {$0 as? Loadout}
			let inserted: [Loadout]? = (note.userInfo?[NSInsertedObjectsKey] as? NSSet)?.allObjects.compactMap {$0 as? Loadout}.compactMap{(try? storageContext.existingObject(with: $0.objectID)) ?? nil}
			self?.presenter?.didUpdateLoaoduts(updated: updated, inserted: inserted, deleted: deleted)
		}
	}
}
