//
//  NCMailPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCMailPageViewController: NCPageViewController {
	
	var inboxViewController: NCMailViewController?
	var corporationViewController: NCMailViewController?
	var allianceViewController: NCMailViewController?
	var sentViewController: NCMailViewController?
	var draftsViewController: NCMailViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		/*inboxViewController = storyboard!.instantiateViewController(withIdentifier: "NCMailViewController") as? NCMailViewController
		inboxViewController?.folder = NSLocalizedString("Inbox", comment: "")

		corporationViewController = storyboard!.instantiateViewController(withIdentifier: "NCMailViewController") as? NCMailViewController
		corporationViewController?.folder = NSLocalizedString("Corporation", comment: "")

		allianceViewController = storyboard!.instantiateViewController(withIdentifier: "NCMailViewController") as? NCMailViewController
		allianceViewController?.folder = NSLocalizedString("Alliance", comment: "")

		sentViewController = storyboard!.instantiateViewController(withIdentifier: "NCMailViewController") as? NCMailViewController
		sentViewController?.folder = NSLocalizedString("Sent", comment: "")

		draftsViewController = storyboard!.instantiateViewController(withIdentifier: "NCMailViewController") as? NCMailViewController
		draftsViewController?.folder = NSLocalizedString("Drafts", comment: "")
		
		draftsViewController?.treeController.content = NCDraftsNode()

		viewControllers = [inboxViewController!, corporationViewController!, allianceViewController!, sentViewController!, draftsViewController!]
		
		navigationItem.rightBarButtonItem = editButtonItem
		
		fetch(from: nil)*/
		
		reload()
	}
	
	func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		guard let account = NCAccount.current else {return}
		let dataManager = NCDataManager(account: account)
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
		
		progress.progress.perform {
			dataManager.mailLabels { result in
				switch result {
				case let .success(value, _):
					var controllers = value.labels?.map { label -> NCMailViewController in
						let controller = self.storyboard?.instantiateViewController(withIdentifier: "NCMailViewController") as! NCMailViewController
						controller.label = label
						return controller
					}
					self.viewControllers = controllers
				case let .failure(error):
					break
				}
				progress.finish()
			}
		}
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

	func reload1(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
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
	
	private var inbox = TreeNode()
	private var sent = TreeNode()
	private var alliance = TreeNode()
	private var corporation = TreeNode()

	private func fetch(from: Int64?, completionHandler: (() -> Void)? = nil) {
		guard !isEndReached, !isFetching else {return}
		let dataManager = self.dataManager
		let characterID = dataManager.characterID
		isFetching = true
		
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
		progress.progress.becomeCurrent(withPendingUnitCount: 1)
		

		func process(headers: [ESI.Mail.Header], contacts: [Int64: NCContact], cacheRecord: NCCacheRecord?) {
			
			if !headers.isEmpty {
				
				var folders = [self.inbox, self.corporation, self.alliance, self.sent].map {
					return $0.children.map { i -> NCDateSection in
						let section = NCDateSection(date: (i as! NCDateSection).date)
						section.children = i.children
						return section
					}
				}
				
				var lastID = self.lastID
				
				DispatchQueue.global(qos: .background).async {
					autoreleasepool {
						let calendar = Calendar(identifier: .gregorian)

						headers.filter {$0.mailID != nil && $0.timestamp != nil}.sorted{$0.mailID! > $1.mailID!}.forEach { header in
							let folder: (NCMailRow.Folder, Int)
							if characterID == Int64(header.from ?? 0) {
								folder = (.sent, 3)
							}
							else {
								let recipient = header.recipients?.first
								switch recipient?.recipientType {
								case .alliance?:
									folder = (.alliance, 2)
								case .character?:
									folder = (.inbox, 0)
								case .corporation?:
									folder = (.corporation, 1)
								case .mailingList?:
									folder = (.mailingList(contacts[Int64(recipient!.recipientID)]?.name), 0)
								default:
									folder = (.unknown, 0)
								}
							}
							
							let row = NCMailRow(mail: header, folder: folder.0, contacts: contacts, cacheRecord: cacheRecord, dataManager: dataManager)
							
							if let section = folders[folder.1].last, section.date < header.timestamp! {
								section.children.append(row)
							}
							else {
								
								let components = calendar.dateComponents([.year, .month, .day], from: header.timestamp!)
								let date = calendar.date(from: components) ?? header.timestamp!
								let section = NCDateSection(date: date)
								section.children = [row]
								folders[folder.1].append(section)
							}
						}
						
						lastID = headers.flatMap{$0.mailID}.min() ?? lastID
						
						
						DispatchQueue.main.async {
							let pages = [self.inbox, self.corporation, self.alliance, self.sent]
							
							self.lastID = lastID
							
							let controllers = [self.inboxViewController, self.corporationViewController, self.allianceViewController, self.sentViewController]
							UIView.performWithoutAnimation {
								pages.enumerated().forEach {
									$0.element.children = folders[$0.offset]
									controllers[$0.offset]?.error = nil
									controllers[$0.offset]?.treeController.content = $0.element
								}
							}
							self.isFetching = false
							self.fetchIfNeeded()
							completionHandler?()
							progress.finish()

						}
					}
				}
			}
			else {
				self.isFetching = false
				self.isEndReached = true
				completionHandler?()
				progress.finish()

			}
		}
		

		dataManager.returnMailHeaders(lastMailID: from) { result in
			switch result {
			case let .success(value, cacheRecord):
				var ids = Set<Int64>()
				for mail in value {
					ids.formUnion(mail.recipients?.flatMap {Int64($0.recipientID)} ?? [])
					if let from = mail.from {
						ids.insert(Int64(from))
					}
				}
				if ids.count > 0 {
					self.dataManager.contacts(ids: ids) { result in
						process(headers: value, contacts: result, cacheRecord: cacheRecord)
					}
				}
				else {
					process(headers: value, contacts: [:], cacheRecord: cacheRecord)
				}
				
			case let .failure(error):
				self.isEndReached = true
				self.isFetching = false
				for controller in [self.inboxViewController, self.corporationViewController, self.allianceViewController, self.sentViewController] {
					controller?.error = error
				}
				completionHandler?()
				progress.finish()
			}
		}
		progress.progress.resignCurrent()
	}
}
