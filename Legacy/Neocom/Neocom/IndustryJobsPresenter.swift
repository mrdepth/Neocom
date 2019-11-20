//
//  IndustryJobsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/9/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import EVEAPI

class IndustryJobsPresenter: TreePresenter {
	typealias View = IndustryJobsViewController
	typealias Interactor = IndustryJobsInteractor
	typealias Presentation = [Tree.Item.IndustryJobRow]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.IndustryJobCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let activeStatus = Set<ESI.Industry.JobStatus>([.active, .paused])
		var jobs = content.value.jobs
		let i = jobs.partition {activeStatus.contains($0.currentStatus)}
		
		let active = jobs[i...].sorted{$0.endDate < $1.endDate}
			.map { Tree.Item.IndustryJobRow($0, location: content.value.locations?[$0.stationID]) }
		
		let finished = jobs[..<i].sorted{$0.endDate > $1.endDate}
			.map { Tree.Item.IndustryJobRow($0, location: content.value.locations?[$0.stationID]) }
		
		return .init(active + finished)
	}
}
