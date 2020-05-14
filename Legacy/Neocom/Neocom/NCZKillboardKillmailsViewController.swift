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
import Futures

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
		return fetch(page: nil).then(on: .main) { result -> [NCCacheRecord] in
			return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
		}
	}

	override func content() -> Future<TreeNode?> {
		return .init(kills)
	}
	
	private func process(result: CachedValue<[ZKillboard.Killmail]>) -> Future<Void> {
		let killsNode = self.kills
		var kills = killsNode.children as? [NCKillmailRow] ?? []

		let dataManager = self.dataManager
		
		return DispatchQueue.global(qos: .utility).async { () -> Void in
			guard let killmails = result.value, !killmails.isEmpty else {throw NCTreeViewControllerError.noResult}
			
			for killmail in killmails {
				let row = NCKillmailRow(killmail: killmail, dataManager: dataManager)
                kills.append(row)
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
