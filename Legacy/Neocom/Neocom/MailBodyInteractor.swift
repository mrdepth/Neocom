//
//  MailBodyInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/2/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class MailBodyInteractor: ContentProviderInteractor {
	typealias Presenter = MailBodyPresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	struct Value {
		var body: ESI.Mail.MailBody
		var contacts: [Int64: Contact]
	}
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	private var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let header = presenter?.view?.input, let mailID = header.mailID else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}

		var set = Set(header.recipients?.map{Int64($0.recipientID)} ?? [])
		if let id = header.from {
			set.insert(Int64(id))
		}
		
		
		let api = self.api
		return api.mailBody(mailID: Int64(mailID), cachePolicy: cachePolicy).then { body in
			api.contacts(with: set).then { contacts in
				body.map{ Value(body: $0, contacts: contacts) }
			}
		}
	}
	
}
