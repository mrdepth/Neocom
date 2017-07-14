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
		inboxViewController = storyboard!.instantiateViewController(withIdentifier: "NCMailViewController") as? NCMailViewController
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
	
	private var inbox: [Int64: NCMailRow] = [:]
	private var sent: [Int64: NCMailRow] = [:]
	private var alliance: [Int64: NCMailRow] = [:]
	private var corporation: [Int64: NCMailRow] = [:]


	
	private func fetch(from: Int64?, completionHandler: (() -> Void)? = nil) {
		guard !isEndReached, !isFetching else {return}
		let dataManager = self.dataManager
		let characterID = dataManager.characterID
		isFetching = true
		
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
		progress.progress.becomeCurrent(withPendingUnitCount: 1)
		

		func process(headers: [ESI.Mail.Header], contacts: [Int64: NCContact], cacheRecord: NCCacheRecord?) {
			
			if headers.count > 0 {
				var inbox = self.inbox
				var sent = self.sent
				var corporation = self.corporation
				var alliance = self.alliance
				var lastID = self.lastID
				
				DispatchQueue.global(qos: .background).async {
					autoreleasepool {
						for header in headers {
							guard let mailID = header.mailID else {continue}
							guard header.timestamp != nil else {continue}
							
							let folder: NCMailRow.Folder
							if characterID == Int64(header.from ?? 0) {
								folder = .sent
								sent[mailID] = NCMailRow(mail: header, folder: folder, contacts: contacts, cacheRecord: cacheRecord, dataManager: dataManager)
							}
							else {
								let recipient = header.recipients?.first
								switch recipient?.recipientType {
								case .alliance?:
									folder = .alliance
									alliance[mailID] = NCMailRow(mail: header, folder: folder, contacts: contacts, cacheRecord: cacheRecord, dataManager: dataManager)
								case .character?:
									folder = .inbox
									inbox[mailID] = NCMailRow(mail: header, folder: folder, contacts: contacts, cacheRecord: cacheRecord, dataManager: dataManager)
								case .corporation?:
									folder = .corporation
									corporation[mailID] = NCMailRow(mail: header, folder: folder, contacts: contacts, cacheRecord: cacheRecord, dataManager: dataManager)
								case .mailingList?:
									folder = .mailingList(contacts[Int64(recipient!.recipientID)]?.name)
									inbox[mailID] = NCMailRow(mail: header, folder: folder, contacts: contacts, cacheRecord: cacheRecord, dataManager: dataManager)
								default:
									folder = .unknown
								}
							}
							lastID = lastID == nil ? mailID : min(mailID, lastID!)
						}
						
						let pages = [inbox, corporation, alliance, sent].map {$0.values.sorted(by: {$0.mail.mailID! > $1.mail.mailID!})}
						
						DispatchQueue.main.async {
							self.lastID = lastID
							self.inbox = inbox
							self.corporation = corporation
							self.alliance = alliance
							self.sent = sent
							
							let controllers = [self.inboxViewController, self.corporationViewController, self.allianceViewController, self.sentViewController]
							UIView.performWithoutAnimation {
								for (i, page) in pages.enumerated() {
									let node = TreeNode()
									node.children = page
									controllers[i]?.treeController.content = node
									controllers[i]?.error = nil
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
