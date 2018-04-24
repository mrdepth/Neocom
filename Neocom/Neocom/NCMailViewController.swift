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

enum NCMailViewControllerError: Error {
	case isEndReached
}


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
				_ = NCDataManager(account: NCAccount.current).markRead(mail: node.mail)
			}
		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCMailRow else {return nil}
		guard let mailID = node.mail.mailID else {return nil}
		let header = node.mail
		
		return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { [weak self] (_,_) in
			guard let strongSelf = self else {return}
			guard let cell = self?.treeController?.cell(for: node) else {return}
			strongSelf.tableView.isUserInteractionEnabled = false

			
			let progress = NCProgressHandler(view: cell, totalUnitCount: 1, activityIndicatorStyle: .white)
			progress.progress.perform {
				strongSelf.dataManager.delete(mailID: mailID).then(on: .main) { result in
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
				}.catch(on: .main) { error in
					strongSelf.present(UIAlertController(error: error), animated: true, completion: nil)
				}.finally(on: .main) {
					self?.tableView.isUserInteractionEnabled = true
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
	private var mails: TreeNode = TreeNode()
//	private var result: CachedValue<[ESI.Mail.Header]>?
	private var contacts: [Int64: NCContact] = [:]
//	private var error: Error?

	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		lastID = nil
		isEndReached = false
		mails = TreeNode()
		return fetch(from: nil).then(on: .main) { result in
			return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
		}
	}
	
	override func content() -> Future<TreeNode?> {
		return .init(mails)
	}
	
	private func process(result: CachedValue<[ESI.Mail.Header]>) -> Future<Void> {
		guard let label = self.label else {
			return .init(.failure(NCTreeViewControllerError.noResult))
		}
		
		var children = mails.children.map { i -> NCDateSection in
			let section = NCDateSection(date: (i as! NCDateSection).date)
			section.children = i.children
			return section
		}

		let dataManager = self.dataManager

		var lastID: Int64? = nil

		return DispatchQueue.global(qos: .utility).async { () -> Void in
			guard let headers = result.value, !headers.isEmpty else {throw NCTreeViewControllerError.noResult}
			
			self.updateContacts(result: result).wait()
			let contacts = self.contacts
			
			let calendar = Calendar(identifier: .gregorian)
			
			headers.filter {$0.mailID != nil && $0.timestamp != nil}.sorted{$0.mailID! > $1.mailID!}.forEach {
				header in
				let row = NCMailRow(mail: header, label: label, contacts: contacts, cacheRecord: result.objectID, dataManager: dataManager)
				
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
		}.then(on: .main) { () -> Void in
			UIView.performWithoutAnimation {
				self.mails.children = children
			}
			self.lastID = lastID
			self.isEndReached = false
			self.fetchIfNeeded()
		}.catch(on: .main) { error in
			self.isEndReached = true
		}
	}
	
	private func updateContacts(result: CachedValue<[ESI.Mail.Header]>) -> Future<Void> {
		let promise = Promise<Void>()
		var ids = Set<Int64>()
		result.value?.forEach { mail in
			ids.formUnion(Set(mail.recipients?.compactMap {Int64($0.recipientID)} ?? []))
			if let from = mail.from {
				ids.insert(Int64(from))
			}
		}
		ids.subtract(contacts.keys)
		if !ids.isEmpty {
			Progress(totalUnitCount: 1).perform {
				self.dataManager.contacts(ids: ids).then(on: .main) { result in
					let context = NCCache.sharedCache?.viewContext
					result.values.compactMap { (try? context?.existingObject(with: $0)) as? NCContact }.forEach {
						self.contacts[$0.contactID] = $0
					}
					try! promise.fulfill(())
				}.catch{error in
					try! promise.fail(error)
				}
			}
		}
		else {
			try! promise.fulfill(())
		}
		return promise.future
	}
	
	private func fetch(from: Int64?) -> Future<CachedValue<[ESI.Mail.Header]>> {
		guard let label = label,
			let labelID = label.labelID,
			!isEndReached, !isFetching else {return .init(.failure(NCTreeViewControllerError.noResult))}
		
		isFetching = true
		let progress = Progress(totalUnitCount: 1)
		return progress.perform{
			dataManager.returnMailHeaders(lastMailID: from, labels: [Int64(labelID)]).then(on: .main) { result in
				return self.process(result: result).then {
					return result
				}
			}.finally(on: .main) {
				self.isFetching = false
			}
		}
	}
	
	private func fetchIfNeeded() {
		if let lastID = lastID, tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 {
			guard !isEndReached, !isFetching else {return}
			
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			progress.progress.perform {
				fetch(from: lastID).then { _ in
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
