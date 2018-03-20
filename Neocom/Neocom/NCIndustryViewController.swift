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
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		switch owner {
		case .character:
			dataManager.industryJobs().then(on: .main) { result in
				self.jobs = result
				completionHandler([result.cacheRecord].flatMap {$0})
			}.catch(on: .main) { error in
				self.error = error
				completionHandler([])
			}
		case .corporation:
			dataManager.corpIndustryJobs().then(on: .main) { result in
				self.corpJobs = result
				completionHandler([result.cacheRecord].flatMap {$0})
			}.catch(on: .main) { error in
				self.error = error
				completionHandler([])
			}
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		let jobs = self.jobs
		let corpJobs = self.corpJobs
		let progress = Progress(totalUnitCount: 3)
		
		OperationQueue(qos: .utility).async { () -> [TreeNode] in
			guard let value: [NCIndustryJob] = jobs?.value ?? corpJobs?.value else {return []}
			let locationIDs = Set(value.map {$0.locationID})
			let locations = try? progress.perform{ self.dataManager.locations(ids: locationIDs) }.get()
			
			return NCDatabase.sharedDatabase!.performTaskAndWait { managedObjectContext in
				var open = value.filter {$0.status == .active || $0.status == .paused}.map {NCIndustryRow(job: $0, location: locations?[$0.locationID])}
				var closed = value.filter {$0.status != .active && $0.status != .paused}.map {NCIndustryRow(job: $0, location: locations?[$0.locationID])}
				
				open.sort {$0.job.endDate < $1.job.endDate}
				closed.sort {$0.job.endDate > $1.job.endDate}
				
				var rows = open
				rows.append(contentsOf: closed)
				return rows
			}
		}.then(on: .main) { sections in
			if self.treeController?.content == nil {
				self.treeController?.content = RootNode(sections)
			}
			else {
				self.treeController?.content?.children = sections
			}
		}.catch(on: .main) {error in
			self.error = error
		}.finally(on: .main) {
			self.tableView.backgroundView = self.treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: self.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private var jobs: CachedValue<[ESI.Industry.Job]>?
	private var corpJobs: CachedValue<[ESI.Industry.CorpJob]>?
	private var error: Error?

	
}
