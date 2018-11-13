//
//  KillmailsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/13/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class KillmailsPresenter: ContentProviderPresenter {
	typealias View = KillmailsViewController
	typealias Interactor = KillmailsInteractor
	struct Presentation {
		var kills: [Section]
		var losses: [Section]
	}
	
	struct Section {
		var date: Date
		var rows: [Tree.Item.KillmailRow]
	}
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let old = presentation
		if numberOfPages == nil {
			numberOfPages = content.value.pages
		}
		
		return DispatchQueue.global(qos: .utility).async { () -> Presentation in
			let calendar = Calendar(identifier: .gregorian)

			let characterID = Int(content.value.characterID)

			var rows = content.value.killmails
				.sorted{$0.killmailTime > $1.killmailTime}
				.map{ i -> Tree.Item.KillmailRow in
					let contactID = i.victim.characterID == characterID ? i.attackers.first.flatMap {$0.characterID ?? $0.corporationID ?? $0.allianceID} : i.victim.characterID
					
					let contact = contactID.flatMap{content.value.contacts?[Int64($0)]}
					
					return Tree.Item.KillmailRow(i, name: contact)
			}

			let i = rows.partition {$0.content.victim.characterID == characterID}
			
			let kills = Dictionary(grouping: rows[..<i], by: { (i) -> Date in
				let components = calendar.dateComponents([.year, .month, .day], from: i.content.killmailTime)
				return calendar.date(from: components) ?? i.content.killmailTime
			}).sorted {$0.key > $1.key}

			let losses = Dictionary(grouping: rows[i...], by: { (i) -> Date in
				let components = calendar.dateComponents([.year, .month, .day], from: i.content.killmailTime)
				return calendar.date(from: components) ?? i.content.killmailTime
			}).sorted {$0.key > $1.key}
			
			if var result = old {
				for i in kills {
					if let j = result.kills.upperBound(where: {$0.date <= i.key}).indices.first, result.kills[j].date == i.key {
						let killmailIDs = Set(result.kills[j].rows.map{$0.content.killmailID})
						result.kills[j].rows.append(contentsOf: i.value.filter {!killmailIDs.contains($0.content.killmailID)})
					}
					else {
						result.kills.append(Section(date: i.key, rows: i.value))
					}
				}
				
				for i in losses {
					if let j = result.losses.upperBound(where: {$0.date <= i.key}).indices.first, result.losses[j].date == i.key {
						let killmailIDs = Set(result.losses[j].rows.map{$0.content.killmailID})
						result.losses[j].rows.append(contentsOf: i.value.filter {!killmailIDs.contains($0.content.killmailID)})
					}
					else {
						result.losses.append(Section(date: i.key, rows: i.value))
					}
				}
				return result

			}
			else {
				return Presentation(kills: kills.map{Section(date: $0.key, rows: $0.value)},
									losses: losses.map{Section(date: $0.key, rows: $0.value)})
			}
		}
	}
	
	private var currentPage: Int?
	private var numberOfPages: Int?
	
	func prepareForReload() {
		self.presentation = nil
		self.currentPage = nil
		self.numberOfPages = nil
	}
	
	@discardableResult
	func fetchIfNeeded() -> Future<Void> {
		guard let numberOfPages = numberOfPages, self.loading == nil else {return .init(.failure(NCError.reloadInProgress))}
		let nextPage = (currentPage ?? 1) + 1
		guard nextPage < numberOfPages else {return .init(.failure(NCError.isEndReached))}
		
		let loading = interactor.load(page: nextPage, cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self] content -> Future<Presentation> in
			guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
			return strongSelf.presentation(for: content).then(on: .main) { [weak self] presentation -> Future<Presentation> in
				guard let strongSelf = self, let view = strongSelf.view else {throw NCError.cancelled(type: type(of: self), function: #function)}
				strongSelf.presentation = presentation
				strongSelf.currentPage = nextPage
				strongSelf.loading = nil
				return view.present(presentation, animated: false).then {_ in presentation}
			}
		}.catch(on: .main) { [weak self] error in
			self?.loading = nil
			self?.currentPage = self?.numberOfPages
		}

		if case .pending = loading.state {
			self.loading = loading
		}
		return loading.then{_ in ()}
	}
}
