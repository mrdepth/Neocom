//
//  NCCalendarViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import Futures

class NCCalendarViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		
	}
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		return dataManager.calendarEvents().then(on: .main) { result -> [NCCacheRecord] in
			self.events = result
			return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
		}
	}
	
	override func content() -> Future<TreeNode?> {
		return DispatchQueue.global(qos: .utility).async { () -> TreeNode? in
			guard let value = self.events?.value else {throw NCTreeViewControllerError.noResult}
			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .none
			dateFormatter.doesRelativeDateFormatting = true
			
			let currentDate = Date()
			let events = value.filter {$0.eventDate != nil && $0.eventDate! >= currentDate}.sorted {$0.eventDate! > $1.eventDate!}
			
			let calendar = Calendar(identifier: .gregorian)
			var date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: events.first?.eventDate ?? Date())) ?? Date()
			
			var sections = [TreeNode]()
			
			var rows = [NCEventRow]()
			for event in events {
				let row = NCEventRow(event: event)
				if event.eventDate! > date {
					rows.append(row)
				}
				else {
					if !rows.isEmpty {
						let title = dateFormatter.string(from: date)
						sections.append(DefaultTreeSection(nodeIdentifier: title, title: title.uppercased(), children: rows.reversed()))
					}
					date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: event.eventDate!)) ?? Date()
					rows = [row]
				}
			}
			
			if !rows.isEmpty {
				let title = dateFormatter.string(from: date)
				sections.append(DefaultTreeSection(nodeIdentifier: title, title: title.uppercased(), children: rows.reversed()))
			}
			
			guard !sections.isEmpty else {throw NCTreeViewControllerError.noResult}
			sections.reverse()
			return RootNode(sections)
		}
	}
	
	//MARK: - NCRefreshable
	
	private var events: CachedValue<[ESI.Calendar.Summary]>?
	
}
