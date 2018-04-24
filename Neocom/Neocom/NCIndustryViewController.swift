//
//  NCIndustryViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCIndustryViewController: NCTreeViewController {
	var owner = Owner.character

	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
	}
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		switch owner {
		case .character:
			return dataManager.industryJobs().then(on: .main) { result -> [NCCacheRecord] in
				self.jobs = result
				return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
			}
		case .corporation:
			return dataManager.corpIndustryJobs().then(on: .main) { result -> [NCCacheRecord] in
				self.corpJobs = result
				return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
			}
		}
	}
	
	override func content() -> Future<TreeNode?> {
		let jobs = self.jobs
		let corpJobs = self.corpJobs
		let progress = Progress(totalUnitCount: 3)
		
		return DispatchQueue.global(qos: .utility).async { () -> TreeNode? in
			guard let value: [NCIndustryJob] = jobs?.value ?? corpJobs?.value else {throw NCTreeViewControllerError.noResult}
			let locationIDs = Set(value.map {$0.locationID})
			let locations = try? progress.perform{ self.dataManager.locations(ids: locationIDs) }.get()
			
			return try NCDatabase.sharedDatabase!.performTaskAndWait { managedObjectContext in
				var open = value.filter {$0.status == .active || $0.status == .paused}.map {NCIndustryRow(job: $0, location: locations?[$0.locationID])}
				var closed = value.filter {$0.status != .active && $0.status != .paused}.map {NCIndustryRow(job: $0, location: locations?[$0.locationID])}
				
				open.sort {$0.job.endDate < $1.job.endDate}
				closed.sort {$0.job.endDate > $1.job.endDate}
				
				var rows = open
				rows.append(contentsOf: closed)
				
				guard !rows.isEmpty else {throw NCTreeViewControllerError.noResult}
				return RootNode(rows)
			}
		}
	}
	
	private var jobs: CachedValue<[ESI.Industry.Job]>?
	private var corpJobs: CachedValue<[ESI.Industry.CorpJob]>?

	
}
