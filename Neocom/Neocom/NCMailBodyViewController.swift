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
		textView.delegate = self
		textView.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.caption]
		
		guard let mail = self.mail, let account = NCAccount.current, let mailID = mail.mailID else {return}
		
		subjectLabel.text = mail.subject ?? " "
		if let date = mail.timestamp {
			dateLabel.text = NCMailRow.dateFormatter.string(from: date)
			self.title = dateLabel.text
		}
		
	
		let dataManager = NCDataManager(account: account)
		
		var ids = Set<Int64>(mail.recipients?.compactMap {Int64($0.recipientID)} ?? [])
		if let from = mail.from {
			ids.insert(Int64(from))
		}
		
		if ids.count > 0 {
			dataManager.contacts(ids: ids).then(on: .main) { result in
				let context = NCCache.sharedCache?.viewContext
				let contacts = Dictionary(result.values.compactMap {(try? context?.existingObject(with: $0)) as? NCContact}.map {($0.contactID, $0)},
										  uniquingKeysWith: { (first, _) in first})

				if let from = mail.from, let contact = contacts[Int64(from)] {
					self.fromLabel.text = contact.name
				}
				let to = mail.recipients?.compactMap { recipient -> String? in
					guard let contact = contacts[Int64(recipient.recipientID)] else {return nil}
					return contact.name
				}.joined(separator: ", ")
				self.toLabel.text = to
				self.contacts = contacts
			}
		}
		
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
		
		dataManager.returnMailBody(mailID: Int64(mailID)).then(on: .main) { result in
			guard let value = result.value else {return}
			let font = self.textView.font ?? UIFont.preferredFont(forTextStyle: .footnote)
			//				let html = "<body style=\"color:white;font-size: \(font.pointSize);font-family: '\(font.familyName)';\">\(value.body ?? "")</body>"
			let html = value.body ?? ""
			if let s = try? NSAttributedString(data: html.data(using: .utf8) ?? Data(),
											   options: [.documentType : NSAttributedString.DocumentType.html,
														 .characterEncoding: String.Encoding.utf8.rawValue,
														 .defaultAttributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .footnote)]],
											   documentAttributes: nil) {
				let body = NSMutableAttributedString(attributedString: s)
				s.enumerateAttributes(in: NSMakeRange(0, s.length), options: []) { (attributes, range, stop) in
					attributes.keys.filter {$0 != NSAttributedStringKey.link}.forEach {
						body.removeAttribute($0, range: range)
					}
				}
				self.body = body * [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: font]
				self.textView.attributedText = self.body
			}
		}.catch(on: .main) { error in
			self.textView.text = error.localizedDescription
		}.finally(on: .main) {
			progress.finish()
			self.updateConstraints(self.textView)
		}
	}
	
	private var textViewWidth: CGFloat?
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if textViewWidth != textView.frame.width {
			textViewWidth = textView.frame.width
			updateConstraints(textView)
		}
	}

	@IBAction func onReply(_ sender: Any) {
		guard let account = NCAccount.current else {return}
		let recipients: [NCContact]
		
		if account.characterID == Int64(mail?.from ?? 0) {
			recipients = mail?.recipients?.compactMap { recipient -> NCContact? in
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
			s = "\n\n" * [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: font] + ("--------------------------------\n" + body) * [NSAttributedStringKey.foregroundColor: UIColor.lightText, NSAttributedStringKey.font: UIFont.italicSystemFont(ofSize: font.pointSize)]
		}
		else {
			s = nil
		}
		
		Router.Mail.NewMessage(recipients: recipients.map{$0.contactID}, subject: "RE: \(mail?.subject ?? "")", body: s).perform(source: self, sender: nil)
	}
	
	private func updateConstraints(_ textView: UITextView) {
		textView.setContentOffset(.zero, animated: false)
		let size = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
		let heightConstraint = textView.constraints.first {$0.firstAttribute == .height && ($0.firstItem as? UITextView) == textView}
		heightConstraint?.constant = max(size.height.rounded(.up), 32)
		self.view.layoutIfNeeded()
		textView.layoutIfNeeded()
	}

}


extension NCMailBodyViewController: UITextViewDelegate {
	func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
		if UIApplication.shared.canOpenURL(URL) {
			UIApplication.shared.openURL(URL)
		}
		return false
	}
}
