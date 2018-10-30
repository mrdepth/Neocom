//
//  MySkillsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class MySkillsPresenter: ContentProviderPresenter {
	typealias View = MySkillsViewController
	typealias Interactor = MySkillsInteractor
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
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let progress = Progress(totalUnitCount: 1)
		
		Services.sde.performBackgroundTask { context in
			let frc = context.managedObjectContext
				.from(SDEInvType.self)
				.filter(\SDEInvType.published == true && \SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue)
				.sort(by: \SDEInvType.group?.groupName, ascending: true)
				.sort(by: \SDEInvType.typeName, ascending: true)
				.fetchedResultsController(sectionName: \SDEInvType.group?.groupName, cacheName: nil)
			
			try frc.performFetch()
			
			let partialProgress = progress.performAsCurrent(withPendingUnitCount: 1) { Progress(totalUnitCount: Int64(frc.sections!.count)) }
			
			for section in frc.sections! {
				
			}
		}
		
		return .init([])
	}
}
