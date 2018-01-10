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


class NCMailViewController: NCTreeViewController {
	
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
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		if let node = node as? NCMailRow {
			if node.mail.isRead != true {
				var mail = node.mail
				mail.isRead = true
				treeController.reloadCells(for: [node])
				guard let record = node.cacheRecord else {return}
				guard var headers: [ESI.Mail.Header] = record.get() else {return}
				guard let i = headers.index(where: {$0.mailID == node.mail.mailID}) else {return}
				var header = headers[i]
				header.isRead = true
				headers[i] = header
				record.set(headers)
				if record.managedObjectContext?.hasChanges == true {
					try? record.managedObjectContext?.save()
				}
				if let unread = label?.unreadCount, unread > 0 {
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
		
		return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { [weak self] (_,_) in
			guard let cell = self?.treeController?.cell(for: node) else {return}
			self?.tableView.isUserInteractionEnabled = false

			
			let progress = NCProgressHandler(view: cell, totalUnitCount: 1, activityIndicatorStyle: .white)
			progress.progress.perform {

				self?.dataManager.delete(mailID: mailID) { result in
					self?.tableView.isUserInteractionEnabled = true
					
					switch result {
					case .success:
						guard let record = node.cacheRecord else {return}
						guard var headers: [ESI.Mail.Header] = record.get() else {return}
						guard let i = headers.index(where: {$0.mailID == node.mail.mailID}) else {return}
						headers.remove(at: i)
						
						guard let strongSelf = self else {return}
						
						if header.isRead == false, let unread = strongSelf.label?.unreadCount, unread > 0 {
							strongSelf.label?.unreadCount = unread - 1
							strongSelf.updateTitle()
							(strongSelf.parent as? NCMailPageViewController)?.saveUnreadCount()
						}
						
						record.set(headers)
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
					progress.finish()
				}
			}
		})]
	}
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		fetchIfNeeded()
	}
	
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
	private var mails: TreeNode?
	private var result: NCCachedResult<[ESI.Mail.Header]>?
	private var contacts: [Int64: NCContact] = [:]

	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		lastID = nil
		isEndReached = false
		mails = nil
		fetch(from: nil) { result in
			completionHandler([result.cacheRecord].flatMap {$0})
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		mails = TreeNode()
		update(result: result, completionHandler: completionHandler)
	}
	
	private func update(result: NCCachedResult<[ESI.Mail.Header]>?, completionHandler: @escaping () -> Void) {
		guard let mails = mails else {
			completionHandler()
			self.isFetching = false
			return
		}
		
		if let label = self.label, let headers = result?.value, !headers.isEmpty {
			updateContacts(result: result) {
				var children = mails.children.map { i -> NCDateSection in
					let section = NCDateSection(date: (i as! NCDateSection).date)
					section.children = i.children
					return section
				}
				
				var lastID = self.lastID
				let cacheRecord = result?.cacheRecord
				let dataManager = self.dataManager
				let contacts = self.contacts
				
				DispatchQueue.global(qos: .background).async {
					autoreleasepool {
						let calendar = Calendar(identifier: .gregorian)
						headers.filter {$0.mailID != nil && $0.timestamp != nil}.sorted{$0.mailID! > $1.mailID!}.forEach {
							header in
							let row = NCMailRow(mail: header, label: label, contacts: contacts, cacheRecord: cacheRecord, dataManager: dataManager)
							
							if let section = children.last, section.date < header.timestamp! {
								section.children.append(row)
							}
							else {
								
								let components = calendar.dateComponents([.year, .month, .day], from: header.timestamp!)
								let date = calendar.date(from: components) ?? header.timestamp!
								let section = NCDateSection(date: date)
								section.children = [row]
								children.append(section)
							}
							lastID = header.mailID
						}
						
						DispatchQueue.main.async {
							UIView.performWithoutAnimation {
								mails.children = children
								self.treeController?.content = mails
							}
							
							self.lastID = lastID
							
							self.isFetching = false
							self.fetchIfNeeded()
							completionHandler()
							self.tableView.backgroundView = mails.children.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Messages", comment: "")) : nil
						}
					}
				}
			}
		}
		else {
			self.isFetching = false
			self.isEndReached = true
			completionHandler()
			self.tableView.backgroundView = mails.children.isEmpty ? NCTableViewBackgroundLabel(text: result?.error?.localizedDescription ?? NSLocalizedString("No Messages", comment: "")) : nil
		}
	}
	
	private func updateContacts(result: NCCachedResult<[ESI.Mail.Header]>?, completionHandler: @escaping () -> Void) {
		var ids = Set<Int64>()
		result?.value?.forEach { mail in
			ids.formUnion(Set(mail.recipients?.flatMap {Int64($0.recipientID)} ?? []))
			if let from = mail.from {
				ids.insert(Int64(from))
			}
		}
		ids.formSymmetricDifference(Set(contacts.keys))
		if !ids.isEmpty {
			Progress(totalUnitCount: 1).perform {
				self.dataManager.contacts(ids: ids) { result in
					result.forEach {
						self.contacts[$0.key] = $0.value
					}
					completionHandler()
				}
			}
		}
		else {
			completionHandler()
		}
	}
	
	private func fetch(from: Int64?, completionHandler: ((NCCachedResult<[ESI.Mail.Header]>) -> Void)? = nil) {
		guard let label = label else {return}
		guard let labelID = label.labelID else {return}
		guard !isEndReached, !isFetching else {return}
		isFetching = true
		
		dataManager.returnMailHeaders(lastMailID: from, labels: [Int64(labelID)]) { result in
			self.result = result
			
			self.update(result: result) {
				completionHandler?(result)
			}
		}
	}
	
	private func fetchIfNeeded() {
		if let lastID = lastID, tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 {
			guard !isEndReached, !isFetching else {return}
			
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			progress.progress.perform {
				fetch(from: lastID) { _ in
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
