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


class NCMailViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	@IBOutlet var segmentedControl: UISegmentedControl!

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)

		tableView.register([Prototype.NCHeaderTableViewCell.default])
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		treeController.content = inbox
//		fetch(from: nil)
		reload()
	}
	
	@IBAction func onChangeSegment(_ sender: UISegmentedControl) {
		UIView.performWithoutAnimation {
			switch sender.selectedSegmentIndex {
			case 0:
				treeController.content = inbox
			case 1:
				treeController.content = sent
			case 2:
				treeController.content = drafts
			default:
				break
			}
			updateBackground()
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			self.fetchIfNeeded()
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let route = (node as? TreeNodeRoutable)?.route {
			route.perform(source: self, view: treeController.cell(for: node))
		}
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
				dataManager.markRead(mail: node.mail) { _ in
					
				}
			}
		}
	}
	
	func treeControllerDidUpdateContent(_ treeController: TreeController) {
		updateBackground()
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		if let node = node as? NCMailRow {
			guard let mailID = node.mail.mailID else {return []}
			let dataManager = self.dataManager
			return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { _ in
				dataManager.delete(mailID: mailID) { [weak self] result in
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
						if let i = self?.inbox.children.index(of: node) {
							self?.inbox.children.remove(at: i)
						}
						if let i = self?.sent.children.index(of: node) {
							self?.sent.children.remove(at: i)
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
		fetchIfNeeded()
	}
	
	//MARK: - Private
	
	@objc private func refresh() {
		guard !isFetching else {
			refreshControl?.endRefreshing()
			return
		}
		let progress = NCProgressHandler(totalUnitCount: 1)
		progress.progress.becomeCurrent(withPendingUnitCount: 1)
		reload(cachePolicy: .reloadIgnoringLocalCacheData) {
			self.refreshControl?.endRefreshing()
		}
		progress.progress.resignCurrent()
	}

	
	private lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
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
		guard segmentedControl.selectedSegmentIndex == 0 || segmentedControl.selectedSegmentIndex == 1 else {return}
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
	}
	
	private func updateBackground() {
		switch segmentedControl.selectedSegmentIndex {
		case 0:
			tableView.backgroundView = inbox.children.count == 0 ? NCTableViewBackgroundLabel(text: error == nil ? NSLocalizedString("No Messages", comment: "") : error!.localizedDescription) : nil
		case 1:
			tableView.backgroundView = sent.children.count == 0 ? NCTableViewBackgroundLabel(text: error == nil ? NSLocalizedString("No Messages", comment: "") : error!.localizedDescription) : nil
		case 2:
			tableView.backgroundView = (drafts?.children.count ?? 0) == 0 ? NCTableViewBackgroundLabel(text: error == nil ? NSLocalizedString("No Messages", comment: "") : error!.localizedDescription) : nil
		default:
			break
		}

	}
}
