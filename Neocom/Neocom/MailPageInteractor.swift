//
//  MailPageInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/2/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class MailPageInteractor: TreeInteractor {
	typealias Presenter = MailPagePresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	struct Value {
		var headers: [ESI.Mail.Header]
		var contacts: [Int64: Contact]
	}
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		return load(from: nil, cachePolicy: cachePolicy)
	}
	
	func load(from lastMailID: Int64?, cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let input = presenter?.view?.input, let labelID = input.labelID else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		let headers = api.mailHeaders(lastMailID: lastMailID, labels: [Int64(labelID)], cachePolicy: cachePolicy)
		return headers.then(on: .main) { mails -> Future<Content> in
			return self.contacts(for: mails.value).then(on: .main) { contacts -> Content in
				return mails.map { Value(headers: $0, contacts: contacts) }
			}
		}
	}
	
	func contacts(for mails: [ESI.Mail.Header]) -> Future<[Int64: Contact]> {
		var ids = Set(mails.compactMap { mail in mail.recipients?.map{Int64($0.recipientID)} }.joined())
		ids.formUnion(mails.compactMap {$0.from.map{Int64($0)}})
		guard !ids.isEmpty else {return .init([:])}
		return api.contacts(with: ids)
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
	
	func delete(_ mail: ESI.Mail.Header) -> Future<Void> {
		guard let mailID = mail.mailID else { return .init(.failure(NCError.invalidArgument(type: type(of: self), function: #function, argument: "mail", value: mail)))}
		return api.delete(mailID: Int64(mailID)).then { _ -> Void in}
	}
	
	func markRead(_ mail: ESI.Mail.Header) {
		_ = api.markRead(mail: mail)
	}
}
