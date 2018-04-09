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
	
//	private var result: CachedValue<[ZKillboard.Killmail]>?

	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		page = nil
		isEndReached = false
		kills = TreeNode()
		return fetch(page: nil).then { result -> [NCCacheRecord] in
			return [result.cacheRecord]
		}
	}

	override func content() -> Future<TreeNode?> {
		return .init(kills)
	}
	
	private func process(result: CachedValue<[ZKillboard.Killmail]>) -> Future<Void> {
		let killsNode = self.kills
		var kills = killsNode.children.map { i -> NCDateSection in
			let section = NCDateSection(date: (i as! NCDateSection).date)
			section.children = i.children
			return section
		}

		let dataManager = self.dataManager
		
		return OperationQueue(qos: .utility).async { () -> Void in
			guard let killmails = result.value, !killmails.isEmpty else {throw NCTreeViewControllerError.noResult}
			
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
		}.then(on: .main) { () -> Void in
			UIView.performWithoutAnimation {
				killsNode.children = kills
			}
			
			self.page = (self.page ?? 1) + 1
			self.isEndReached = false
			self.fetchIfNeeded()
		}.catch(on: .main) { _ in
			self.isEndReached = true
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
	private var kills: TreeNode = TreeNode()
	
	private func fetchIfNeeded() {
		if let page = page, tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 {
			guard !isEndReached, !isFetching else {return}

			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			progress.progress.perform {
				fetch(page: page).then { _ in
					progress.finish()
				}
			}
		}
	}


	private func fetch(page: Int?) -> Future<CachedValue<[ZKillboard.Killmail]>> {
		guard let filter = filter else {return .init(.failure(NCTreeViewControllerError.noResult))}
		guard !isEndReached, !isFetching else {return .init(.failure(NCTreeViewControllerError.noResult))}
		
		let dataManager = self.dataManager
		isFetching = true

		let progress = Progress(totalUnitCount: 1)
		
		return progress.perform {
			dataManager.zKillmails(filter: filter, page: page ?? 1).then(on: .main) { result in
				return self.process(result: result).then { () -> CachedValue<[ZKillboard.Killmail]> in
					return result
				}
			}.finally(on: .main) {
				self.isFetching = false
			}
		}
	}
	
}
