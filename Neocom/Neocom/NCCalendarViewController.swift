//
//  NCCalendarViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCCalendarViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		needsReloadOnAccountChange = true
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		dataManager.calendarEvents { result in
			self.events = result
			
			if let cacheRecord = result.cacheRecord {
				completionHandler([cacheRecord])
			}
			else {
				completionHandler([])
			}
			
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = events?.value {
			tableView.backgroundView = nil
			
			DispatchQueue.global(qos: .background).async {
				autoreleasepool {
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
					sections.reverse()
					
					DispatchQueue.main.async {
						
						if self.treeController?.content == nil {
							self.treeController?.content = RootNode(sections)
						}
						else {
							self.treeController?.content?.children = sections
						}
						self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
						completionHandler()
					}
					
				}
			}
			
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: events?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	//MARK: - NCRefreshable
	
	private var events: NCCachedResult<[ESI.Calendar.Summary]>?
	
}
