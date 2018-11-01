//
//  MySkillsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI
import CoreData

class MySkillsInteractor: ContentProviderInteractor {
	typealias Presenter = MySkillsPresenter
	typealias Content = ESI.Result<Character>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	private var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		return api.character(cachePolicy: cachePolicy)
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	private var managedObjectContextObjectsDidChangeObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			self?.api = Services.api.current
			_ = self?.presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter?.view?.present(presentation, animated: true)
			}
		}
		
		managedObjectContextObjectsDidChangeObserver = NotificationCenter.default.addNotificationObserver(forName: .NSManagedObjectContextObjectsDidChange, object: Services.storage.viewContext.managedObjectContext, queue: nil) { [weak self] (note) in
			self?.managedObjectContextObjectsDidChange(note)
		}
	}
	
	private func managedObjectContextObjectsDidChange(_ note: Notification) {
		guard let skillPlan = Services.storage.viewContext.currentAccount?.activeSkillPlan else {return}
		guard skillPlan.changedValues().keys.contains(where: {$0 == "active" || $0 == "skills"}) else {return}
		presenter?.didUpdateSkillPlan()
	}

}
