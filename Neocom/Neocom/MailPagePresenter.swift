//
//  MailPagePresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/2/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import EVEAPI

class MailPagePresenter: TreePresenter {
	typealias View = MailPageViewController
	typealias Interactor = MailPageInteractor
	typealias Presentation = [Tree.Item.DateSection<Tree.Item.MailRow>]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	var lastMailID: Int64?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeHeaderCell.default,
								  Prototype.MailCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let input = view?.input else {return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		guard !content.value.headers.isEmpty else {return .init(.failure(NCError.noResults))}
		guard let characterID = Services.storage.viewContext.currentAccount?.characterID else {return .init(.failure(NCError.authenticationRequired))}
		
		let treeController = view?.treeController
		let old = self.presentation ?? []
		let api = interactor.api
		
		return DispatchQueue.global(qos: .utility).async { () -> (Presentation, Int?) in
			let calendar = Calendar(identifier: .gregorian)
			
			let headers = content.value.headers.filter{$0.mailID != nil && $0.timestamp != nil}.sorted{$0.mailID! > $1.mailID!}.map { header -> Tree.Item.MailRow in
				var ids = Set(header.recipients?.map{Int64($0.recipientID)} ?? [])
				if let from = header.from {
					ids.insert(Int64(from))
				}
				
				return Tree.Item.MailRow(header,
										 contacts: content.value.contacts.filter {ids.contains($0.key)},
										 label: input,
										 characterID: characterID,
										 api: api)
			}
			
			let sections = Dictionary(grouping: headers, by: { (i) -> Date in
				let components = calendar.dateComponents([.year, .month, .day], from: i.content.timestamp!)
				return calendar.date(from: components) ?? i.content.timestamp!
			}).sorted {$0.key > $1.key}
				.map{Tree.Item.DateSection(date: $0.key,
										   diffIdentifier: $0.key,
										   treeController: treeController,
										   children: $0.value)}
			return (sections, headers.last?.content.mailID)
			
		}.then(on: .main) { [weak self] (new, lastMailID) -> Presentation in
			self?.lastMailID = lastMailID.map{Int64($0)}
			var result = old
			for i in new {
				if let j = old.upperBound(where: {$0.date <= i.date}).first, j.date == i.date {
					let mailIDs = Set(j.children?.compactMap {$0.content.mailID} ?? [])
					j.children?.append(contentsOf: i.children?.filter {$0.content.mailID != nil && !mailIDs.contains($0.content.mailID!)} ?? [])
				}
				else {
					result.append(i)
				}
			}
			return result
		}
	}
	
	func reloadIfNeeded() {
		if let content = content, presentation != nil, !interactor.isExpired(content) {
			return
		}
		else {
			let animated = presentation != nil
			self.presentation = nil
			self.lastMailID = nil
			self.isEndReached = false
			reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self] presentation in
				self?.view?.present(presentation, animated: animated)
			}.catch(on: .main) { [weak self] error in
				self?.isEndReached = true
				self?.view?.fail(error)
			}
		}
	}
	
	private var isEndReached = false
	func fetchIfNeeded() {
		guard !isEndReached && loading == nil else {return}
		view?.activityIndicator.startAnimating()
		reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self] presentation in
			self?.view?.present(presentation, animated: false)
		}.catch(on: .main) { [weak self] error in
			self?.isEndReached = true
		}.finally(on: .main) { [weak self] in
			self?.view?.activityIndicator.stopAnimating()
		}
	}
	
	func canEdit<T: TreeItem>(_ item: T) -> Bool {
		return item is Tree.Item.MailRow
	}
	
	func editingStyle<T: TreeItem>(for item: T) -> UITableViewCell.EditingStyle {
		return item is Tree.Item.MailRow ? .delete : .none
	}
	
	func editActions<T: TreeItem>(for item: T) -> [UITableViewRowAction]? {
		guard let item = item as? Tree.Item.MailRow else {return nil}
		
		return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { [weak self] (_, _) in
			self?.interactor.delete(item.content).then(on: .main) {
				guard let bound = self?.presentation?.upperBound(where: {$0.date <= item.content.timestamp!}) else {return}
				guard let section = bound.first else {return}
				guard let i = section.children?.firstIndex(of: item) else {return}
				section.children?.remove(at: i)
				
				if section.children?.isEmpty == true {
					self?.presentation?.remove(at: bound.indices.first!)
					if let presentation = self?.presentation {
						_ = self?.view?.treeController.reloadData(presentation, with: .fade)
					}
				}
				else {
					self?.view?.treeController.update(contentsOf: section, with: .fade)
				}
				
				if let n = self?.view?.input?.unreadCount, item.content.isRead != true && n > 0 {
					self?.view?.input?.unreadCount = n - 1
					self?.view?.updateTitle()
				}
				
			}.catch(on: .main) { [weak self] error in
				self?.view?.present(UIAlertController(error: error), animated: true, completion: nil)
			}
		}]
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let view = view else {return}
		guard let item = item as? Tree.Item.MailRow else {return}
		if item.content.isRead != true {
			item.content.isRead = true
			interactor.markRead(item.content)
			if let n = view.input?.unreadCount, n > 0 {
				view.input?.unreadCount = n - 1
				view.updateTitle()
			}
			
			if let cell = view.treeController.cell(for: item) {
				item.configure(cell: cell, treeController: view.treeController)
			}
			else {
				view.treeController.reloadRow(for: item, with: .none)
			}
		}
		Router.Mail.mailBody(item.content).perform(from: view)
	}
}


extension Tree.Item {
	class DateSection<Element: TreeItem>: Section<Element> {
		let date: Date
		
		init<T: Hashable>(date: Date, doesRelativeDateFormatting: Bool = true, diffIdentifier: T, expandIdentifier: CustomStringConvertible? = nil, treeController: TreeController?, children: [Element]? = nil) {
			self.date = date
			
			let formatter = DateFormatter()
			formatter.doesRelativeDateFormatting = doesRelativeDateFormatting
			formatter.timeStyle = .none
			formatter.dateStyle = .medium
			let title = formatter.string(from: date).uppercased()
			super.init(Tree.Content.Section(prototype: Prototype.TreeHeaderCell.default,
											title: title,
											isExpanded: true),
					   diffIdentifier: diffIdentifier,
					   expandIdentifier: expandIdentifier,
					   treeController: treeController, children: children)
		}
	}
}
