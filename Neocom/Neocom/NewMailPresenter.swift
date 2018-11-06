//
//  NewMailPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CloudData

class NewMailPresenter: Presenter {
	typealias View = NewMailViewController
	typealias Interactor = NewMailInteractor
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
		
		guard let view = view, let input = view.input else {return}
		recipients = input.recipients ?? []
		view.fromLabel.text = Services.storage.viewContext.currentAccount?.characterName
		view.subjectTextView.text = input.subject
		view.textView.attributedText = input.body
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	var recipients: [Contact] = [] {
		didSet {
			guard let toTextView = view?.toTextView else {return}
			
			var s = NSAttributedString()
			for contact in recipients {
				let i = ((contact.name ?? "") + ", ") * [NSAttributedString.Key.foregroundColor: UIColor.caption, NSAttributedString.Key.font: toTextView.font!]
				let rect = i.boundingRect(with: .zero, options: [.usesLineFragmentOrigin], context: nil)
				UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
				i.draw(in: rect)
				let image = UIGraphicsGetImageFromCurrentImageContext()
				UIGraphicsEndImageContext()
				
				s = s + (NSAttributedString(image: image, font: toTextView.font!) * [NSAttributedString.Key.recipientID: contact.contactID])
			}
			
			s = s * toTextView.typingAttributes
			toTextView.attributedText = s
		}
	}
	
	func didSelectContact(_ contact: Contact) {
		guard !recipients.contains(contact) else {return}
		view?.view.endEditing(true)
		view?.searchResultsViewController?.presenter.updateSearchResults(with: nil)
		recipients.append(contact)
	}
	
	func removeRecipient(with id: Int64) {
		recipients.removeAll {$0.contactID == id}
	}
	
	func searchContacts(with string: String?) {
		view?.searchResultsViewController?.presenter.updateSearchResults(with: string)
	}
}
