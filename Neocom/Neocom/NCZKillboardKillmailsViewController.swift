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
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCKillmailTableViewCell.default
			])
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		registerRefreshable()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController.content == nil {
			reload()
		}
	}
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		fetchIfNeeded()
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let route = (node as? TreeNodeRoutable)?.route {
			route.perform(source: self, view: treeController.cell(for: node))
		}
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
	private var kills = TreeNode()
	
	private func fetchIfNeeded() {
		if let page = page, tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 {
			guard !isEndReached, !isFetching else {return}

			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			progress.progress.perform {
				fetch(page: page) {
					progress.finish()
				}
			}
		}
	}


	private func fetch(page: Int?, completionHandler: (() -> Void)? = nil) {
		guard let filter = filter else {return}
		guard !isEndReached, !isFetching else {return}
		let dataManager = self.dataManager
		isFetching = true

		let progress = Progress(totalUnitCount: 1)
		
		func process(killmails: [ZKillboard.Killmail]) {
			if !killmails.isEmpty {
				var kills = self.kills.children.map { i -> NCDateSection in
					let section = NCDateSection(date: (i as! NCDateSection).date)
					section.children = i.children
					return section
				}
				
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
								self.kills.children = kills
								self.treeController.content = self.kills
							}
							
							self.page = (self.page ?? 1) + 1
							
							self.isFetching = false
							self.fetchIfNeeded()
							completionHandler?()
							self.tableView.backgroundView = self.kills.children.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
						}
					}
				}
				
				
			}
			else {
				self.isFetching = false
				self.isEndReached = true
				completionHandler?()
				self.tableView.backgroundView = self.kills.children.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
			}
		}
		
		progress.perform {
			dataManager.zKillmails(filter: filter, page: page ?? 1) { result in
				switch result {
				case let .success(value, _):
					process(killmails: value)
				case let .failure(error):
					self.isEndReached = true
					self.isFetching = false
					self.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
					completionHandler?()
				}
			}
		}
	}
	
}
