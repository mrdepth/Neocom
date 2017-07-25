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
			updateTitle()
		}
	}

	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCMailTableViewCell.default])
		registerRefreshable()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController?.content == nil {
			reload()
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		if let node = node as? NCMailRow {
			if node.mail.isRead != true {
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
				if let unread = label?.unreadCount, unread > 0 {
					label = label?.copy() as? ESI.Mail.MailLabelsAndUnreadCounts.Label
					label?.unreadCount = unread - 1
					(parent as? NCMailPageViewController)?.saveUnreadCount()
				}
				updateTitle()
				NCDataManager(account: NCAccount.current).markRead(mail: node.mail) { _ in
					
				}
			}
		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCMailRow else {return nil}
		guard let mailID = node.mail.mailID else {return nil}
		let header = node.mail
		
		return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { [weak self] _ in
			self?.tableView.isUserInteractionEnabled = false
			self?.dataManager.delete(mailID: mailID) { result in
				self?.tableView.isUserInteractionEnabled = true
				
				switch result {
				case .success:
					guard let record = node.cacheRecord else {return}
					guard var headers = record.data?.data as? [ESI.Mail.Header] else {return}
					guard let i = headers.index(where: {$0.mailID == node.mail.mailID}) else {return}
					headers.remove(at: i)

					guard let strongSelf = self else {return}

					if header.isRead == false, let unread = strongSelf.label?.unreadCount, unread > 0 {
						strongSelf.label = strongSelf.label?.copy() as? ESI.Mail.MailLabelsAndUnreadCounts.Label
						strongSelf.label?.unreadCount = unread - 1
						strongSelf.updateTitle()
						(strongSelf.parent as? NCMailPageViewController)?.saveUnreadCount()
					}
					
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
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		fetchIfNeeded()
	}
	
	//MARK: NCRefreshable
	
	private lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
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
				
				var lastID = self.lastID
				
				DispatchQueue.global(qos: .background).async {
					autoreleasepool {
						let calendar = Calendar(identifier: .gregorian)
						headers.filter {$0.mailID != nil && $0.timestamp != nil}.sorted{$0.mailID! > $1.mailID!}.forEach {
							 header in
							let row = NCMailRow(mail: header, label: label, contacts: contacts, cacheRecord: cacheRecord, dataManager: dataManager)

							if let section = mails.last, section.date < header.timestamp! {
								section.children.append(row)
							}
							else {
								
								let components = calendar.dateComponents([.year, .month, .day], from: header.timestamp!)
								let date = calendar.date(from: components) ?? header.timestamp!
								let section = NCDateSection(date: date)
								section.children = [row]
								mails.append(section)
							}
							lastID = header.mailID
						}

						DispatchQueue.main.async {
							UIView.performWithoutAnimation {
								self.mails.children = mails
								self.treeController?.content = self.mails
							}
							
							self.lastID = lastID
							
							self.isFetching = false
							self.fetchIfNeeded()
							completionHandler?()
							self.tableView.backgroundView = self.mails.children.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Messages", comment: "")) : nil
						}
					}
				}
				
				
			}
			else {
				self.isFetching = false
				self.isEndReached = true
				completionHandler?()
				self.tableView.backgroundView = self.mails.children.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Messages", comment: "")) : nil
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
	
	private func updateTitle() {
		guard let label = label else {return}
		if let unreadCount = label.unreadCount, unreadCount > 0 {
			title = "\(label.name ?? "") (\(unreadCount))"
		}
		else {
			title = label.name
		}
	}

}
