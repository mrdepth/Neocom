//
//  NCMailViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI


class NCMailViewController: NCTreeViewController, NCRefreshable {
	
	var label: ESI.Mail.MailLabelsAndUnreadCounts.Label? {
		didSet {
			guard let label = label else {return}
			if let unreadCount = label.unreadCount, unreadCount > 0 {
				title = "\(label.name ?? "") (\(unreadCount))"
			}
			else {
				title = label.name
			}
		}
	}

	var folder: String = "" {
		didSet {
			updateTitle()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		registerRefreshable()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
//		updateBackground()
	}
	
	var error: Error? {
		didSet {
//			updateBackground()
		}
	}
	
	/*func updateBackground() {
		if (treeController.content?.children.count ?? 0) > 0 {
			tableView.backgroundView = nil
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: error == nil ? NSLocalizedString("No Messages", comment: "") : error!.localizedDescription)
		}
	}*/

	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		if let node = node as? NCMailRow {
			if node.mail.isRead == false {
				node.mail.isRead = true
				treeController.reloadCells(for: [node])
				guard let record = node.cacheRecord else {return}
				guard var headers = record.data?.data as? [ESI.Mail.Header] else {return}
				guard let i = headers.index(where: {$0.mailID == node.mail.mailID}) else {return}
				let mail = headers[i].copy() as! ESI.Mail.Header
				mail.isRead = true
				headers[i] = mail
				record.data?.data = headers as NSArray
				if record.managedObjectContext?.hasChanges == true {
					try? record.managedObjectContext?.save()
				}
				updateTitle()
				NCDataManager(account: NCAccount.current).markRead(mail: node.mail) { _ in
					
				}
			}
		}
	}
	
	func treeControllerDidUpdateContent(_ treeController: TreeController) {
//		updateBackground()
//		updateTitle()
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		if let node = node as? NCMailRow {
			guard let mailID = node.mail.mailID else {return []}
			let dataManager = NCDataManager(account: NCAccount.current)
			return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { [weak self] _ in
				self?.tableView.isUserInteractionEnabled = false
				dataManager.delete(mailID: mailID) { result in
					self?.tableView.isUserInteractionEnabled = true
					
					switch result {
					case .success:
						guard let record = node.cacheRecord else {return}
						guard var headers = record.data?.data as? [ESI.Mail.Header] else {return}
						guard let i = headers.index(where: {$0.mailID == node.mail.mailID}) else {return}
						headers.remove(at: i)
						
						record.data?.data = headers as NSArray
						if record.managedObjectContext?.hasChanges == true {
							try? record.managedObjectContext?.save()
						}
						if let parent = node.parent, let i = parent.children.index(of: node) {
							parent.children.remove(at: i)
							if parent.children.isEmpty, let root = parent.parent, let i = root.children.index(of: parent) {
								root.children.remove(at: i)
							}
						}
					case .failure:
						break
					}
				}
			})]
		}
		else if let node = node as? NCDraftRow {
			return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { _ in
				node.object.managedObjectContext?.delete(node.object)
				if node.object.managedObjectContext?.hasChanges == true {
					try? node.object.managedObjectContext?.save()
				}
			})]
		}
		else {
			return nil
		}
	}
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		(parent as? NCMailPageViewController)?.fetchIfNeeded()
	}
	
	//MARK: NCRefreshable
	
	private lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
	private var isEndReached = false
	private var isFetching = false
	private var lastID: Int64?
	private var mails = TreeNode()

	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		lastID = nil
		isEndReached = false
		mails = TreeNode()
		self.dataManager = NCDataManager(account: NCAccount.current, cachePolicy: cachePolicy)
		fetch(from: nil, completionHandler: completionHandler)
	}
	
	private func fetch(from: Int64?, completionHandler: (() -> Void)? = nil) {
		guard let label = label else {return}
		guard let labelID = label.labelID else {return}
		guard !isEndReached, !isFetching else {return}
		let dataManager = self.dataManager
		isFetching = true
		
		let progress = Progress(totalUnitCount: 1)
		
		func process(headers: [ESI.Mail.Header], contacts: [Int64: NCContact], cacheRecord: NCCacheRecord?) {
			if !headers.isEmpty {
				var mails = self.mails.children.map { i -> NCDateSection in
					let section = NCDateSection(date: (i as! NCDateSection).date)
					section.children = i.children
					return section
				}
				
				DispatchQueue.global(qos: .background).async {
					autoreleasepool {
						let calendar = Calendar(identifier: .gregorian)
						headers.filter {$0.mailID != nil && $0.timestamp != nil}.sorted{$0.mailID! > $1.mailID!}.forEach {
							 header in
							let row = NCMailRow(mail: header, label: label, contacts: contacts, cacheRecord: cacheRecord, dataManager: dataManager)
							
						}
						for header in headers {
							let row = NCKillmailRow(killmail: killmail, dataManager: dataManager)
							
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
			dataManager.returnMailHeaders(lastMailID: from, labels: [Int64(labelID)]) { result in
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
					self.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
					completionHandler?()
				}
			}
		}
	}
	
	private func fetchIfNeeded() {
		if let lastID = lastID, tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 {
			guard !isEndReached, !isFetching else {return}
			
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			progress.progress.perform {
				fetch(from: lastID) {
					progress.finish()
				}
			}
		}
	}

	
	//MARK: - Private
	
	@objc private func refresh() {
		guard let parent = parent as? NCMailPageViewController, !parent.isFetching else {
			refreshControl?.endRefreshing()
			return
		}
		parent.reload(cachePolicy: .reloadIgnoringLocalCacheData) {
			self.refreshControl?.endRefreshing()
		}
	}

	/*private func updateTitle() {
		let i: Int
		if let mails = treeController.content?.children as? [NCMailRow] {
			i = mails.filter {$0.mail.isRead == false}.count
		}
		else if let drafts = treeController.content?.children as? [NCDraftRow] {
			i = drafts.count
		}
		else {
			i = 0
		}

		if i > 0 {
			title = "\(folder) (\(i))"
		}
		else {
			title = folder
		}
	}*/
	
/*	private lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
	private var isEndReached = false
	private var isFetching = false
	private var inbox = TreeNode()
	private var sent = TreeNode()
	private lazy var drafts = NCDraftsNode()
	private var lastID: Int64?
	private var error: Error?
	
	private func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		self.dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
//		self.inbox.children = []
//		self.sent.children = []
		isEndReached = false
		lastID = nil
		fetch(from: nil, completionHandler: completionHandler)
	}
	
	private func fetchIfNeeded() {
		if let lastID = lastID, self.tableView.contentOffset.y > self.tableView.contentSize.height - self.tableView.bounds.size.height * 2 {
			fetch(from: lastID)
		}
	}
	
	private func fetch(from: Int64?, completionHandler: (() -> Void)? = nil) {
		guard !isEndReached, !isFetching else {return}
		let characterID = dataManager.characterID
		isFetching = true
		
		
		func process(headers: [ESI.Mail.Header], contacts: [Int64: NCContact], cacheRecord: NCCacheRecord?) {
			defer{self.isFetching = false}

			if headers.count > 0 {
				var inbox = self.inbox.children
				var sent = self.sent.children
				for header in headers {
					let folder: NCMailRow.Folder
					if characterID == Int64(header.from ?? 0) {
						folder = .sent
					}
					else {
						let recipient = header.recipients?.first
						switch recipient?.recipientType {
						case .alliance?:
							folder = .alliance
						case .character?:
							folder = .inbox
						case .corporation?:
							folder = .corporation
						case .mailingList?:
							folder = .mailingList(contacts[Int64(recipient!.recipientID)]?.name)
						default:
							folder = .unknown
						}
					}
					if case .sent = folder {
						let row = NCMailRow(mail: header, folder: folder, contacts: contacts, cacheRecord: cacheRecord)
						if let i = sent.index(of: row) {
							sent[i] = row
						}
						else {
							sent.append(row)
						}
					}
					else {
						let row = NCMailRow(mail: header, folder: folder, contacts: contacts, cacheRecord: cacheRecord)
						if let i = inbox.index(of: row) {
							inbox[i] = row
						}
						else {
							inbox.append(row)
						}
					}
				}
				lastID = headers.flatMap{$0.mailID}.min() ?? 0
				
				UIView.performWithoutAnimation {
					self.inbox.children = inbox.sorted(by: {($0 as! NCMailRow).mail.timestamp ?? Date.distantPast > ($1 as! NCMailRow).mail.timestamp ?? Date.distantPast})
					self.sent.children = sent.sorted(by: {($0 as! NCMailRow).mail.timestamp ?? Date.distantPast > ($1 as! NCMailRow).mail.timestamp ?? Date.distantPast})
					self.updateBackground()
				}
				
				DispatchQueue.main.async {
					self.fetchIfNeeded()
				}
			}
			else {
				self.isEndReached = true
			}
			completionHandler?()
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
				self.error = error
				self.isEndReached = true
				self.isFetching = false
				self.updateBackground()
				completionHandler?()
			}
		}
	}*/
	
}
