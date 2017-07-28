//
//  NCFeedChannelViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCFeedChannelViewController: NCTreeViewController {
	
	var url: URL?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		guard let url = url else {
			completionHandler([])
			return
		}
		
		dataManager.rss(url: url) { result in
			self.rss = result
			
			if let cacheRecord = result.cacheRecord {
				completionHandler([cacheRecord])
			}
			else {
				completionHandler([])
			}
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = rss?.value {
			let progress = Progress(totalUnitCount: Int64(value.items?.count ?? 0))
			DispatchQueue.global(qos: .background).async {
				autoreleasepool {
					let dateFormatter = DateFormatter()
					dateFormatter.dateStyle = .medium
					dateFormatter.timeStyle = .none
					dateFormatter.doesRelativeDateFormatting = true
					
					let calendar = Calendar(identifier: .gregorian)
					
					var date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: Date())) ?? Date()
					
					var sections = [TreeNode]()
					var rows = [NCFeedItemRow]()
					
					let items = value.items?.sorted {($0.updated ?? Date()) > ($1.updated ?? Date())}
					
					for item in items ?? [] {
						progress.completedUnitCount += 1
						let row = NCFeedItemRow(item: item)
						let updated = item.updated ?? Date()
						if updated > date {
							rows.append(row)
						}
						else {
							if !rows.isEmpty {
								let title = dateFormatter.string(from: date)
								sections.append(DefaultTreeSection(nodeIdentifier: title, title: title.uppercased(), children: rows))
							}
							date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: updated)) ?? Date()
							rows = [row]
						}
					}
					
					if !rows.isEmpty {
						let title = dateFormatter.string(from: date)
						sections.append(DefaultTreeSection(nodeIdentifier: title, title: title.uppercased(), children: rows))
					}
					
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
			tableView.backgroundView = NCTableViewBackgroundLabel(text: rss?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private var rss: NCCachedResult<RSS.Feed>?
	
}
