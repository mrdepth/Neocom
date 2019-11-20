//
//  MailBodyPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/2/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class MailBodyPresenter: ContentProviderPresenter {
	typealias View = MailBodyViewController
	typealias Interactor = MailBodyInteractor
	
	struct Presentation {
		let from: String?
		let to: String?
		let subject: String?
		let date: String?
		let body: NSAttributedString?
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
		view?.title = view?.input?.subject
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let input = view?.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		let from = input.from.flatMap {content.value.contacts[Int64($0)]}?.name
		let to = input.recipients?.compactMap { content.value.contacts[Int64($0.recipientID)]?.name }.joined(separator: ", ")
		let subject = input.subject
		let date = input.timestamp.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .short) }
		
		let font = view?.textView.font ?? UIFont.preferredFont(forTextStyle: .footnote)
		let body: NSAttributedString?
		
		let html = content.value.body.body ?? ""
		if let s = try? NSAttributedString(data: html.data(using: .utf8) ?? Data(),
										   options: [.documentType : NSAttributedString.DocumentType.html,
													 .characterEncoding: String.Encoding.utf8.rawValue,
													 .defaultAttributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .footnote)]],
										   documentAttributes: nil) {
			let copy = NSMutableAttributedString(attributedString: s)
			s.enumerateAttributes(in: NSMakeRange(0, s.length), options: []) { (attributes, range, stop) in
				attributes.keys.filter {$0 != NSAttributedString.Key.link}.forEach {
					copy.removeAttribute($0, range: range)
				}
			}
			
			body = copy * [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: font]
		}
		else {
			body = nil
		}

		return .init(Presentation(from: from, to: to, subject: subject, date: date, body: body))
	}
	
	func onReply() {
		guard let account = Services.storage.viewContext.currentAccount else {return}
		guard let input = view?.input else { return }
		let recipients: [Contact]
		
		if account.characterID == input.from.map{Int64($0)} {
			recipients = input.recipients?.compactMap { recipient -> Contact? in
				return content?.value.contacts[Int64(recipient.recipientID)]
			} ?? []
		}
		else if let from = input.from, let contact = content?.value.contacts[Int64(from)] {
			recipients = [contact]
		}
		else {
			recipients = []
		}
		let s: NSAttributedString?
		if let body = content?.value.body.body {
			let font = UIFont.preferredFont(forTextStyle: .body)
			s = "\n\n" * [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: font] + ("--------------------------------\n" + body) * [NSAttributedString.Key.foregroundColor: UIColor.lightText, NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: font.pointSize)]
		}
		else {
			s = nil
		}
//
//		Router.Mail.NewMessage(recipients: recipients.map{$0.contactID}, subject: "RE: \(mail?.subject ?? "")", body: s).perform(source: self, sender: nil)
	}
	
}
