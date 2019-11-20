//
//  KillmailsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/13/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class KillmailsInteractor: ContentProviderInteractor {
	typealias Presenter = KillmailsPresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	struct Value {
		var killmails: [ESI.Killmails.Killmail]
		var contacts: [Int64: Contact]?
		var characterID: Int64
		var pages: Int?
	}
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		return load(page: nil, cachePolicy: cachePolicy)
	}
	
	func load(page: Int?, cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let characterID = (Services.storage.viewContext.currentAccount?.characterID).map({Int($0)}) else {return .init(.failure(NCError.authenticationRequired))}
		
		let progress = Progress(totalUnitCount: 3)
		let api = self.api
		return DispatchQueue.global(qos: .utility).async { () -> Content in
			let killmails = try progress.performAsCurrent(withPendingUnitCount: 1) {api.killmails(page: page, cachePolicy: cachePolicy)}.get()
			let partialProgress = progress.performAsCurrent(withPendingUnitCount: 1) {Progress(totalUnitCount: Int64(killmails.value.count))}
			let info = try any(killmails.value.map { killmail -> Future<ESI.Result<ESI.Killmails.Killmail>> in
				partialProgress.performAsCurrent(withPendingUnitCount: 1) {
					api.killmailInfo(killmailHash: killmail.killmailHash, killmailID: Int64(killmail.killmailID), cachePolicy: cachePolicy)
				}
			}).get().compactMap {$0?.value}
			
			var contactIDs = Set(info.filter{$0.victim.characterID != characterID}.compactMap{$0.victim.characterID.map{Int64($0)}})
			
			contactIDs.formUnion(
				info.filter {$0.victim.characterID == characterID}.flatMap {
					$0.attackers.compactMap{$0.characterID ?? $0.corporationID ?? $0.allianceID}
				}.map{Int64($0)}
			)
			
			let contacts = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.contacts(with: contactIDs)}.get()
			let pages = killmails.metadata?["x-pages"].flatMap{Int($0)}
			return killmails.map {_ in Value(killmails: info, contacts: contacts, characterID: Int64(characterID), pages: pages)}
		}
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			self?.api = Services.api.current
			_ = self?.presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter?.view?.present(presentation, animated: true)
			}
		}
	}
}
