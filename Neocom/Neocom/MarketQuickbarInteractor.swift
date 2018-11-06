//
//  MarketQuickbarInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import CoreData

class MarketQuickbarInteractor: TreeInteractor {
	typealias Presenter = MarketQuickbarPresenter
	typealias Content = Void
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		return .init(())
	}
	
	private var managedObjectContextDidSaveObserver: NotificationObserver?
	
	func configure() {
		managedObjectContextDidSaveObserver = NotificationCenter.default.addNotificationObserver(forName: .NSManagedObjectContextDidSave, object: Services.storage.viewContext.managedObjectContext, queue: nil) { [weak self] (note) in
			self?.managedObjectContextDidSave(note)
		}
	}
	
	private func managedObjectContextDidSave(_ note: Notification) {
		guard (note.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.contains(where: {$0 is MarketQuickItem}) == true ||
		(note.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.contains(where: {$0 is MarketQuickItem}) == true else {return}
		_ = presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self] presentation in
			self?.presenter?.view?.present(presentation, animated: true)
		}.catch(on: .main) { [weak self] error in
			self?.presenter?.view?.fail(error)
		}
	}

}
