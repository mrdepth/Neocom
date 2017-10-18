//
//  NCZKillboardKillmailsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI

class NCZKillboardKillmailsViewController: NCTreeViewController {
	
	var filter: [ZKillboard.Filter]?
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCKillmailTableViewCell.default
			])
		
	}
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		fetchIfNeeded()
	}
	
	//MARK: - TreeControllerDelegate
	
	private var result: NCCachedResult<[ZKillboard.Killmail]>?

	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		page = nil
		isEndReached = false
		kills = nil
		fetch(page: nil) { result in
			completionHandler([result.cacheRecord].flatMap {$0})
		}
	}

	
	override func updateContent(completionHandler: @escaping () -> Void) {
		kills = TreeNode()
		update(result: result, completionHandler: completionHandler)
	}
	
	private func update(result: NCCachedResult<[ZKillboard.Killmail]>?, completionHandler: @escaping () -> Void) {
		guard let killsNode = kills else {
			isFetching = false
			completionHandler()
			return
		}
		
		if let killmails = result?.value, !killmails.isEmpty {
			var kills = killsNode.children.map { i -> NCDateSection in
				let section = NCDateSection(date: (i as! NCDateSection).date)
				section.children = i.children
				return section
			}
			
			let dataManager = self.dataManager
			
			DispatchQueue.global(qos: .background).async {
				autoreleasepool {
					let calendar = Calendar(identifier: .gregorian)
					
					for killmail in killmails {
						let row = NCKillmailRow(killmail: killmail, characterID: nil, dataManager: dataManager)
						
						if let section = kills.last, section.date < killmail.killmailTime {
							section.children.append(row)
						}
						else {
							
							let components = calendar.dateComponents([.year, .month, .day], from: killmail.killmailTime)
							let date = calendar.date(from: components) ?? killmail.killmailTime
							let section = NCDateSection(date: date)
							section.children = [row]
							kills.append(section)
						}
					}
					DispatchQueue.main.async {
						UIView.performWithoutAnimation {
							killsNode.children = kills
							self.treeController?.content = killsNode
						}
						
						self.page = (self.page ?? 1) + 1
						
						self.isFetching = false
						self.fetchIfNeeded()
						completionHandler()
						self.tableView.backgroundView = killsNode.children.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
					}
				}
			}
			
			
		}
		else {
			self.isFetching = false
			self.isEndReached = true
			completionHandler()
			self.tableView.backgroundView = killsNode.children.isEmpty ? NCTableViewBackgroundLabel(text: result?.error?.localizedDescription ?? NSLocalizedString("No Results", comment: "")) : nil
		}

	}
	
	//MARK: - Private
	private var page: Int?
	private var isEndReached = false
	private var isFetching = false {
		didSet {
			if isFetching {
				activityIndicator.startAnimating()
			}
			else {
				activityIndicator.stopAnimating()
			}
		}
	}
	private var kills: TreeNode?
	
	private func fetchIfNeeded() {
		if let page = page, tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 {
			guard !isEndReached, !isFetching else {return}

			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			progress.progress.perform {
				fetch(page: page) { _ in
					progress.finish()
				}
			}
		}
	}


	private func fetch(page: Int?, completionHandler: ((NCCachedResult<[ZKillboard.Killmail]>) -> Void)? = nil) {
		guard let filter = filter else {return}
		guard !isEndReached, !isFetching else {return}
		let dataManager = self.dataManager
		isFetching = true

		let progress = Progress(totalUnitCount: 1)
		
		func process(killmails: [ZKillboard.Killmail]) {
		}
		
		progress.perform {
			dataManager.zKillmails(filter: filter, page: page ?? 1) { result in
				self.result = result
				self.update(result: result) {
					completionHandler?(result)
				}
			}
		}
	}
	
}
