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

class NCZKillboardKillmailsViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	
	var filter: [ZKillboard.Filter]?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCKillmailTableViewCell.default
			])
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		registerRefreshable()
		reload()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		fetchIfNeeded()
	}
	
	//MARK: NCRefreshable
	

	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		page = nil
		isEndReached = false
		kills = TreeNode()
		self.dataManager = NCDataManager(account: NCAccount.current, cachePolicy: cachePolicy)
		fetch(page: page, completionHandler: completionHandler)
	}

	//MARK: - Private
	private lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
	private var page: Int?
	private var isEndReached = false
	private var isFetching = false
	private var kills = TreeNode()
	
	private func fetchIfNeeded() {
		if let page = page, tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 {
			fetch(page: page)
		}
	}


	private func fetch(page: Int?, completionHandler: (() -> Void)? = nil) {
		guard let filter = filter else {return}
		guard !isEndReached, !isFetching else {return}
		let dataManager = self.dataManager
		isFetching = true

		let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
		
		func process(killmails: [ZKillboard.Killmail]) {
			if !killmails.isEmpty {
				let node = self.kills
				var kills = self.kills.children
				
				for killmail in killmails {
					let row = NCKillmailRow(killmail: killmail, dataManager: dataManager)
					
					if let section = node.children.last as? NCDateSection, section.date < killmail.killmailTime {
						section.children.append(row)
					}
					else {
						let calendar = Calendar(identifier: .gregorian)
						let components = calendar.dateComponents([.year, .month, .day], from: killmail.killmailTime)
						let date = calendar.date(from: components) ?? killmail.killmailTime
						let section = NCDateSection(date: date)
						section.children = [row]
						kills.append(section)
					}
				}
				UIView.performWithoutAnimation {
					self.kills.children = kills
					self.treeController.content = self.kills
				}

				self.page = (self.page ?? 1) + 1
				
				self.isFetching = false
				self.fetchIfNeeded()
				completionHandler?()
				progress.finish()
				
			}
			else {
				self.isFetching = false
				self.isEndReached = true
				completionHandler?()
				progress.finish()
			}
			self.tableView.backgroundView = self.kills.children.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
		}
		
		progress.progress.perform {
			dataManager.zKillmails(filter: filter, page: page ?? 1) { result in
				switch result {
				case let .success(value, _):
					process(killmails: value)
				case let .failure(error):
					self.isEndReached = true
					self.isFetching = false
					self.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
					completionHandler?()
					progress.finish()
				}
			}
		}
	}
	
}
