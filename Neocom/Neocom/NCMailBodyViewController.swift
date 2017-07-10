//
//  NCMailBodyViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 18.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import WebKit
import CoreData

class NCMailBodyViewController: UIViewController {
	
	@IBOutlet weak var stackView: UIStackView!
	@IBOutlet weak var fromLabel: UILabel!
	@IBOutlet weak var toLabel: UILabel!
	@IBOutlet weak var subjectLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var textView: UITextView!
	
	var mail: ESI.Mail.Header?
	
	private var contacts: [Int64: NCContact]?
	private var body: NSAttributedString?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		textView.linkTextAttributes = [NSForegroundColorAttributeName: UIColor.caption]
		
		guard let mail = self.mail, let account = NCAccount.current, let mailID = mail.mailID else {return}
		
		subjectLabel.text = mail.subject ?? " "
		if let date = mail.timestamp {
			dateLabel.text = NCMailRow.dateFormatter.string(from: date)
			self.title = dateLabel.text
		}
		
	
		let dataManager = NCDataManager(account: account)
		
		var ids = Set<Int64>(mail.recipients?.flatMap {Int64($0.recipientID)} ?? [])
		if let from = mail.from {
			ids.insert(Int64(from))
		}
		
		if ids.count > 0 {
			dataManager.contacts(ids: ids) { contacts in

				if let from = mail.from, let contact = contacts[Int64(from)] {
					self.fromLabel.text = contact.name
				}
				let to = mail.recipients?.flatMap { recipient -> String? in
					guard let contact = contacts[Int64(recipient.recipientID)] else {return nil}
					return contact.name
				}.joined(separator: ", ")
				self.toLabel.text = to
				self.contacts = contacts
			}
		}
		
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
		
		dataManager.returnMailBody(mailID: mailID) { result in
			defer {progress.finish()}
			
			switch result {
			case let .success(value, _):
				let font = self.textView.font ?? UIFont.preferredFont(forTextStyle: .footnote)
				let html = "<body style=\"color:white;font-size: \(font.pointSize);font-family: '\(font.familyName)';\">\(value.body ?? "")</body>"
				let s = try? NSAttributedString(data: html.data(using: .utf8) ?? Data(),
				                                options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
				                                          NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue,
				                                          NSDefaultAttributesDocumentAttribute: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.preferredFont(forTextStyle: .footnote)]],
				                                documentAttributes: nil)
				self.textView.attributedText = s
				self.body = s
			case let .failure(error):
				self.textView.text = error.localizedDescription
			}
			
			let size = self.textView.sizeThatFits(CGSize(width: self.textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
			let heightConstraint = self.textView.constraints.first {$0.firstAttribute == .height && ($0.firstItem as? UITextView) == self.textView}
			heightConstraint?.constant = max(size.height.rounded(.up), 32)

		}
	}
	
	
	@IBAction func onReply(_ sender: Any) {
		guard let account = NCAccount.current else {return}
		let recipients: [NCContact]
		
		if account.characterID == Int64(mail?.from ?? 0) {
			recipients = mail?.recipients?.flatMap { recipient -> NCContact? in
				return self.contacts?[Int64(recipient.recipientID)]
			} ?? []
		}
		else if let from = mail?.from, let contact = contacts?[Int64(from)] {
			recipients = [contact]
		}
		else {
			recipients = []
		}
		let s: NSAttributedString?
		if let body = self.body {
			let font = UIFont.preferredFont(forTextStyle: .body)
			s = "\n\n" * [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: font] + ("--------------------------------\n" + body) * [NSForegroundColorAttributeName: UIColor.lightText, NSFontAttributeName: UIFont.italicSystemFont(ofSize: font.pointSize)]
		}
		else {
			s = nil
		}
		
		Router.Mail.NewMessage(recipients: recipients.map{$0.contactID}, subject: "RE: \(mail?.subject ?? "")", body: s).perform(source: self, view: nil)
	}
}
