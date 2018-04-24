//
//  NCFeedChannelViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCFeedChannelViewController: NCTreeViewController {
	
	var url: URL?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		
	}
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		guard let url = url else {return .init([])}
		return dataManager.rss(url: url).then(on: .main) { result -> [NCCacheRecord] in
			self.rss = result
			return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
		}
	}
	
	override func content() -> Future<TreeNode?> {
		let rss = self.rss
		let totalProgress = Progress(totalUnitCount: 1)
		return DispatchQueue.global(qos: .utility).async { () -> TreeNode? in
			guard let value = rss?.value else {throw NCTreeViewControllerError.noResult}
			let progress = totalProgress.perform{ Progress(totalUnitCount: Int64(value.items?.count ?? 0)) }
			
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
			
			guard !sections.isEmpty else {throw NCTreeViewControllerError.noResult}
			return RootNode(sections)
		}
	}
	
	private var rss: CachedValue<RSS.Feed>?
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let node = node as? NCFeedItemRow else {return}
		guard let url = node.item.link?.absoluteString.lowercased() else {return}
		guard let context = NCCache.sharedCache?.viewContext else {return}
		
		if let link: NCCacheVisitedLink = context.fetch("VisitedLink", where: "url == %@", url) {
			link.date = Date()
		}
		else {
			let link = NCCacheVisitedLink(entity: NSEntityDescription.entity(forEntityName: "VisitedLink", in: context)!, insertInto: context)
			link.url = url
			link.date = Date()
		}
		if context.hasChanges {
			try? context.save()
		}
		node.isVisited = true
		treeController.reloadCells(for: [node])
	}
	
}
