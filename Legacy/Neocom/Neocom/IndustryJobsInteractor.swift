//
//  IndustryJobsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/9/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class IndustryJobsInteractor: TreeInteractor {
	typealias Presenter = IndustryJobsPresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	struct Value {
		var jobs: [ESI.Industry.Job]
		var locations: [Int64: EVELocation]?
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		let api = self.api
		let progress = Progress(totalUnitCount: 2)
		return DispatchQueue.global(qos: .utility).async { () -> Content in
			let jobs = try progress.performAsCurrent(withPendingUnitCount: 1) {api.industryJobs(cachePolicy: cachePolicy)}.get()
			let locationIDs = jobs.value.map{$0.stationID}
			let locations = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.locations(with: Set(locationIDs))}.get()
			return jobs.map {Value(jobs: $0, locations: locations)}
		}
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			self?.api = Services.api.current
			_ = self?.presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter?.view?.present(presentation, animated: true)
			}
		}
	}
}
