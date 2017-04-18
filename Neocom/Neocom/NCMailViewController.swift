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

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		guard let account = NCAccount.current else {return}
		treeController.content = inbox
		fetch(from: nil)
		/*treeController.content = NCMailFetchedResultsNode(account: account)
		
		NCDataManager(account: account).fetchMail { [weak self] result in
			switch result {
			case .success:
				break
			case let .failure(error):
				break
			}
		}*/
	}
	
	@IBAction func onChangeSegment(_ sender: UISegmentedControl) {
		UIView.performWithoutAnimation {
			treeController.content = sender.selectedSegmentIndex == 0 ? inbox : sent
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
	}

	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		fetchIfNeeded()
	}
	
	private lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
	private var isEndReached = false
	private var isFetching = false
	private var inbox = TreeNode()
	private var sent = TreeNode()
	private var lastID: Int64?
	
	private func fetchIfNeeded() {
		if let lastID = lastID, self.tableView.contentOffset.y > self.tableView.contentSize.height - self.tableView.bounds.size.height * 2 {
			fetch(from: lastID)
		}
	}
	
	private func fetch(from: Int64?) {
		guard !isEndReached, !isFetching else {return}
		let characterID = dataManager.characterID
		isFetching = true
		
		
		func process(headers: [ESI.Mail.Header], contacts: [Int64: NSManagedObjectID]) {
			defer{self.isFetching = false}
			if headers.count > 0 {
				guard let context = NCCache.sharedCache?.viewContext else {return}
				
				var contactsMap: [Int64: NCContact] = [:]
				for (key, value) in contacts {
					guard let obj = (try? context.existingObject(with: value)) as? NCContact else {continue}
					contactsMap[key] = obj
				}

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
							folder = .mailingList(contactsMap[Int64(recipient!.recipientID)]?.name)
						default:
							folder = .unknown
						}
					}
					if case .sent = folder {
						sent.append(NCMailRow(mail: header, folder: folder, contacts: contactsMap))
					}
					else {
						inbox.append(NCMailRow(mail: header, folder: folder, contacts: contactsMap))
					}
				}
				lastID = headers.flatMap{$0.mailID}.min() ?? 0
				
				UIView.performWithoutAnimation {
					self.inbox.children = inbox
					self.sent.children = sent
				}
				
				DispatchQueue.main.async {
					self.fetchIfNeeded()
				}
			}
			else {
				self.isEndReached = true
			}
		}
		
		dataManager.returnMailHeaders(lastMailID: from) { result in
			switch result {
			case let .success(value, _):
				var ids = Set<Int64>()
				for mail in value {
					ids.formUnion(mail.recipients?.flatMap {Int64($0.recipientID)} ?? [])
					if let from = mail.from {
						ids.insert(Int64(from))
					}
				}
				if ids.count > 0 {
					self.dataManager.contacts(ids: ids) { result in
						process(headers: value, contacts: result)
					}
				}
				else {
					process(headers: value, contacts: [:])
				}

			case let .failure(error):
				self.isEndReached = true
				self.isFetching = false
			}
		}
	}
}
