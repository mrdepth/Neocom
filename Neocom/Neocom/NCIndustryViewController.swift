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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		needsReloadOnAccountChange = true
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		dataManager.industryJobs { result in
			self.jobs = result
			completionHandler([result.cacheRecord].flatMap {$0})
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = jobs?.value {
			tableView.backgroundView = nil
			
			let locationIDs = Set(value.map {$0.stationID})
			
			dataManager.locations(ids: locationIDs) { locations in

				NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
					
					var open = value.filter {$0.status == .active || $0.status == .paused}.map {NCIndustryRow(job: $0, location: locations[$0.stationID])}
					var closed = value.filter {$0.status != .active && $0.status != .paused}.map {NCIndustryRow(job: $0, location: locations[$0.stationID])}
					
					open.sort {$0.job.endDate < $1.job.endDate}
					closed.sort {$0.job.endDate > $1.job.endDate}
					
					var rows = open
					rows.append(contentsOf: closed)
					
					DispatchQueue.main.async {
						
						if self.treeController?.content == nil {
							self.treeController?.content = RootNode(rows)
						}
						else {
							self.treeController?.content?.children = rows
						}
						
						self.tableView.backgroundView = rows.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
						completionHandler()
					}
				}
			}
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: jobs?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private var jobs: NCCachedResult<[ESI.Industry.Job]>?
	
}
