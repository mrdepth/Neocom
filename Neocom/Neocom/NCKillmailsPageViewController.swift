//
//  NCKillmailsPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCKillmailsPageViewController: NCPageViewController {
	
	var killsViewController: NCKillmailsViewController?
	var lossesViewController: NCKillmailsViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()

		killsViewController = storyboard!.instantiateViewController(withIdentifier: "NCKillmailsViewController") as? NCKillmailsViewController
		lossesViewController = storyboard!.instantiateViewController(withIdentifier: "NCKillmailsViewController") as? NCKillmailsViewController
		
		viewControllers = [killsViewController!, lossesViewController!]
		
		fetch(from: nil)
	}
	
	@IBAction func onCompose(_ sender: Any) {
		Router.Mail.NewMessage().perform(source: self)
	}
	
	private(set) var isFetching = false
	
	func fetchIfNeeded() {
		guard let tableView = (currentPage as? NCMailViewController)?.tableView else {return}
		if let lastID = lastID, tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 {
			fetch(from: lastID)
		}
		
	}
	
	func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		self.dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		isEndReached = false
		lastID = nil
		fetch(from: nil, completionHandler: completionHandler)
	}
	
	//MARK: - Private
	
	private lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
	private var isEndReached = false
	private var lastID: Int64?
	
	private var kills: [NCKillmailRow] = []
	private var losses: [NCKillmailRow] = []
	
	private func fetch(from: Int64?, completionHandler: (() -> Void)? = nil) {
		guard !isEndReached, !isFetching else {return}
		let dataManager = self.dataManager
		let characterID = Int(dataManager.characterID)
		isFetching = true
		
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
		
		
		func process(killmails: [ESI.Killmails.Recent]) {
			
			progress.progress.perform {
				let partial = Progress(totalUnitCount: Int64(killmails.count))
				
				if !killmails.isEmpty {
					var queue = killmails
					
					func pop() {
						if queue.isEmpty {
							if let lastID = killmails.map({$0.killmailID}).min() {
								self.lastID = Int64(lastID)
							}
							self.isFetching = false
							self.fetchIfNeeded()
							completionHandler?()
							progress.finish()
						}
						else {
							let killmail = queue.removeFirst()
							dataManager.killmailInfo(killmailHash: killmail.killmailHash, killmailID: Int64(killmail.killmailID)) { result in
								if let value = result.value {

									if value.victim.characterID == characterID {
										UIView.performWithoutAnimation {
											self.losses.append(NCKillmailRow(killmail: value, dataManager: dataManager))
											self.lossesViewController?.treeController.content?.children = self.losses
											self.lossesViewController?.error = nil
										}
									}
									else {
										UIView.performWithoutAnimation {
											self.kills.append(NCKillmailRow(killmail: value, dataManager: dataManager))
											self.killsViewController?.treeController.content?.children = self.kills
											self.killsViewController?.error = nil
										}
									}
								}
								partial.completedUnitCount += 1
								pop()
							}
						}
					}
					pop()
				}
				else {
					self.isFetching = false
					self.isEndReached = true
					completionHandler?()
					progress.finish()
				}
			}
		}
		
		progress.progress.perform {
			dataManager.killmails(maxKillID: from) { result in
				switch result {
				case let .success(value, _):
					process(killmails: value)
				case let .failure(error):
					self.isEndReached = true
					self.isFetching = false
					for controller in [self.killsViewController, self.lossesViewController] {
						controller?.error = error
					}
					completionHandler?()
					progress.finish()
				}
			}
		}
	}
}
