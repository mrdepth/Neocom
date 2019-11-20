//
//  ContactsSearchResultsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData

class ContactsSearchResultsInteractor: TreeInteractor {
	typealias Presenter = ContactsSearchResultsPresenter
	typealias Content = [Contact]
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let string = presenter?.searchManager.pop() else { return .init(recent ?? [])}
		guard string.count > 2 else { return .init(recent ?? [])}
		
		return api.searchContacts(string, categories: [.character, .corporation, .alliance]).then(on: .main) { result in
			return result.values.sorted {($0.name ?? "") < ($1.name ?? "")}
		}
	}
	
	func search(_ string: String) -> Future<[Int64: Contact]> {
		return api.searchContacts(string, categories: [.character, .corporation, .alliance])
	}
	
	func configure() {
	}
	
	func isExpired(_ content: Content) -> Bool {
		return false
	}
	
	private lazy var recent: [Contact]? = nil
}
