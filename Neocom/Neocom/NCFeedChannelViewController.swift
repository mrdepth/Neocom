//
//  NCFeedChannelViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCFeedChannelViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	var url: URL?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		
		registerRefreshable()
		
		treeController.delegate = self
		
		reload()
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.route?.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
	//MARK: - NCRefreshable
	
	private var observer: NCManagedObjectObserver?
	private var rss: NCCachedResult<RSS.Feed>?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let url = url else {return}
		
		let progress = Progress(totalUnitCount: 2)
		
		let dataManager = NCDataManager(account: NCAccount.current, cachePolicy: cachePolicy)
		
		progress.perform {
			dataManager.rss(url: url) { result in
				self.rss = result
				
				switch result {
				case let .success(_, record):
					if let record = record {
						self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
							self?.reloadSections()
						}
					}
				case .failure:
					break
				}
				progress.perform {
					self.reloadSections() {
						completionHandler?()
					}
				}
			}
		}
	}
	
	private func reloadSections(completionHandler: (() -> Void)? = nil) {
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
						
						if self.treeController.content == nil {
							let root = TreeNode()
							root.children = sections
							self.treeController.content = root
						}
						else {
							self.treeController.content?.children = sections
						}
						self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
						completionHandler?()
					}
					
				}
			}
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: rss?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler?()
		}
	}
	
}
