//
//  NCCalendarViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCCalendarViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	
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
	private var events: NCCachedResult<[ESI.Calendar.Summary]>?
	private var locations: [Int64: NCLocation]?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		
		let progress = Progress(totalUnitCount: 1)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		
		progress.perform {
			dataManager.calendarEvents { result in
				self.events = result
				
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
				
				self.reloadSections()
				completionHandler?()

			}
		}
	}
	
	private func reloadSections() {
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
						
						if self.treeController.content == nil {
							let root = TreeNode()
							root.children = sections
							self.treeController.content = root
						}
						else {
							self.treeController.content?.children = sections
						}
						self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
					}

				}
			}
			
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: events?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
	
}
