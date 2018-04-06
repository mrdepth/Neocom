//
//  NCNewMailViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData


class NCNewMailViewController: UIViewController, UITextViewDelegate, NCContactsSearchResultViewControllerDelegate {
	
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var toTextView: UITextView!
	@IBOutlet weak var subjectTextView: UITextView!
	@IBOutlet weak var bottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var heightConstraint: NSLayoutConstraint!
	@IBOutlet var accessoryView: UIView!
	@IBOutlet weak var fromLabel: UILabel!
	
	var recipients: [Int64] = []
	var subject: String?
	var body: NSAttributedString?
	var draft: NCMailDraft?

	private var _recipients: [Int64: NCContact] = [:]
	
	private lazy var searchResultViewController: NCContactsSearchResultViewController? = {
		let controller = self.childViewControllers.first as? NCContactsSearchResultViewController
		controller?.delegate = self
		return controller
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		update()
		
		fromLabel.text = NCAccount.current?.characterName
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillHide, object: nil)
		
		var label = UILabel(frame: .zero)
		label.attributedText = "To: " * [NSAttributedStringKey.foregroundColor: UIColor.lightText, NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .subheadline)]
		label.sizeToFit()
		label.frame.origin = CGPoint(x: textView.textContainerInset.left, y: textView.textContainerInset.top)
		
		toTextView.addSubview(label)
		toTextView.textContainer.exclusionPaths = [UIBezierPath(rect: label.frame)]
		toTextView.typingAttributes = [NSAttributedStringKey.foregroundColor.rawValue: toTextView.textColor!, NSAttributedStringKey.font.rawValue: toTextView.font!]
		
		label = UILabel(frame: .zero)
		label.attributedText = "Subject: " * [NSAttributedStringKey.foregroundColor: UIColor.lightText, NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .subheadline)]
		label.sizeToFit()
		label.frame.origin = CGPoint(x: textView.textContainerInset.left, y: textView.textContainerInset.top)

		subjectTextView.addSubview(label)
		subjectTextView.textContainer.exclusionPaths = [UIBezierPath(rect: label.frame)]
		
		textView.inputAccessoryView = accessoryView
		textView.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.caption]
		textView.typingAttributes = [NSAttributedStringKey.font.rawValue: UIFont.preferredFont(forTextStyle: .body), NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]

		subjectTextView.text = self.subject
		textView.attributedText = body
		
		if recipients.count > 0 {
			let context = NCCache.sharedCache?.viewContext
			NCDataManager(account: NCAccount.current).contacts(ids: Set(recipients)).then(on: .main) { result in
				result.forEach {self._recipients[$0] = (try? context?.existingObject(with: $1)) as? NCContact}
				self.updateRecipients()
			}
		}
		
		
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	private var textViewWidth: CGFloat?
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if textViewWidth != textView.frame.width {
			textViewWidth = textView.frame.width
			updateConstraints(textView)
			updateConstraints(toTextView)
			updateConstraints(subjectTextView)
		}
	}
	
	@IBAction func onTap(_ sender: UITapGestureRecognizer) {
		let p = sender.location(in: scrollView)
		if p.y > textView.frame.maxY {
			textView.becomeFirstResponder()
		}
	}
	
	@IBAction func onSend(_ sender: Any) {
//		guard let data = try? textView.attributedText.data(from: NSMakeRange(0, textView.attributedText.length), documentAttributes: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType]) else {return}
//		guard let html = String(data: data, encoding: .utf8) else {return}
		let html = textView.attributedText.eveHTML

		let recipients = self.recipients.compactMap { id -> ESI.Mail.Recipient? in
			guard let contact = self._recipients[id] else {return nil}
			contact.lastUse = Date()
			guard let recipientType = contact.recipientType else {return nil}
			return ESI.Mail.Recipient(recipientID: Int(contact.contactID), recipientType: recipientType)
		}
		
		let context = NCCache.sharedCache?.viewContext
		if context?.hasChanges == true {
			try? context?.save()
		}
		
		
		dataManager?.sendMail(body: html, subject: subjectTextView.text, recipients: recipients).then(on: .main) { _ in
			if let draft = self.draft {
				draft.managedObjectContext?.delete(draft)
				if draft.managedObjectContext?.hasChanges == true {
					try? draft.managedObjectContext?.save()
				}
			}
			self.dismiss(animated: true, completion: nil)
		}.catch(on: .main) { error in
			self.present(UIAlertController(error: error), animated: true, completion: nil)
		}
	}
	
	@IBAction func onCancel(_ sender: UIBarButtonItem) {
		if !textView.text.isEmpty {
			let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			controller.addAction(UIAlertAction(title: NSLocalizedString("Delete Draft", comment: ""), style: .destructive, handler: { _ in
				if let draft = self.draft {
					draft.managedObjectContext?.delete(draft)
					if draft.managedObjectContext?.hasChanges == true {
						try? draft.managedObjectContext?.save()
					}
				}
				self.dismiss(animated: true, completion: nil)
			}))
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Save Draft", comment: ""), style: .default, handler: { _ in
				defer {
					self.dismiss(animated: true, completion: nil)
				}
				
				guard let context = NCStorage.sharedStorage?.viewContext else {return}
				
				let draft = self.draft ?? {
					let draft = NCMailDraft(entity: NSEntityDescription.entity(forEntityName: "MailDraft", in: context)!, insertInto: context)
					return draft
				}()
				draft.to = self.recipients
				draft.subject = self.subjectTextView.text
				draft.body = self.textView.attributedText
				draft.date = Date()
				if context.hasChanges {
					try? context.save()
				}
			}))
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
				
			}))
			present(controller, animated: true, completion: nil)
			controller.popoverPresentationController?.barButtonItem = sender
		}
		else {
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	@IBAction func onAttach(_ sender: Any) {
		Router.Mail.Attachments { [weak self] (controller, value) in
			controller.dismiss(animated: true, completion: nil)
			self?.attach(value)
		}.perform(source: self, sender: sender)
	}

	//MARK: - UITextViewDelegate
	
	func textViewDidChange(_ textView: UITextView) {
		updateConstraints(textView)

		if textView == toTextView {
			scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.contentInset.top), animated: true)
			search(toTextView.text ?? "")
		}
		else if textView == self.textView, let selectedTextRange = textView.selectedTextRange  {
			let rect = textView.caretRect(for: selectedTextRange.end)
			scrollView.scrollRectToVisible(textView.convert(rect, to: scrollView), animated: true)
			update()
		}
	}
	
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		if textView == toTextView {
			UIView.animate(withDuration: 0.15, animations: {
				self.searchResultViewController?.view.superview?.alpha = 1.0
			})
		}
	}
	func textViewDidEndEditing(_ textView: UITextView) {
		if textView == toTextView {
			UIView.animate(withDuration: 0.15, animations: {
				self.searchResultViewController?.view.superview?.alpha = 0.0
			})
		}
	}
	
	func textViewDidChangeSelection(_ textView: UITextView) {
		if textView == self.textView {
			textView.typingAttributes = [NSAttributedStringKey.font.rawValue: UIFont.preferredFont(forTextStyle: .body), NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]
		}
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		guard textView == toTextView else {return true}
		if text == "\n" {
			view.endEditing(true)
			return false
		}
		if textView.attributedText.containsAttachments(in: range) {
			if (textView.selectedRange.length == 0) {
				textView.selectedRange = range
				return false
			}
			else {
				textView.attributedText.enumerateAttributes(in: range, options: [], using: { (attributes, _, _) in
//					guard let attachment = attributes[NSAttachmentAttributeName] as? NSTextAttachment else {return}
					guard let recipientID = attributes[.recipientID] as? Int64 else {return}
					guard let i = recipients.index(of: recipientID) else {return}
					recipients.remove(at: i)
					_recipients[recipientID] = nil
				})
			}
		}
		else {
			if textView.attributedText.length > range.location && textView.attributedText.containsAttachments(in: NSMakeRange(range.location, 1)) {
				return false
			}
		}
		return true
	}
	
	//MARK: - NCContactsSearchResultViewControllerDelegate
	
	func contactsSearchResultsViewController(_ controller: NCContactsSearchResultViewController, didSelect contact: NCContact) {
		
		guard !recipients.contains(contact.contactID) else {return}
//		guard let type = contact.recipientType else {return}
		recipients.append(contact.contactID)
		_recipients[contact.contactID] = contact
		
		updateRecipients()
		
		updateConstraints(toTextView)
		
		view.endEditing(true)
		update()
	}
	
	//MARK: - Private
	
	private func updateConstraints(_ textView: UITextView) {
		textView.setContentOffset(.zero, animated: false)
		let size = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
		let heightConstraint = textView.constraints.first {$0.firstAttribute == .height && ($0.firstItem as? UITextView) == textView}
		heightConstraint?.constant = max(size.height.rounded(.up), 32)
		UIView.animate(withDuration: 0.15) {
			self.view.layoutIfNeeded()
			textView.layoutIfNeeded()
		}
	}
	
	@objc private func keyboardWillChangeFrame(_ note: Notification) {
		guard var finalFrame = note.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect else {return}
		finalFrame = view.convert(finalFrame, from: nil)
		
		bottomConstraint.constant = max(view.bounds.maxY - finalFrame.minY, 0)
		view.layoutIfNeeded()
	}
	
	private func search(_ string: String) {
		searchResultViewController?.update(searchString: string)
	}

	private lazy var dataManager: NCDataManager? = {
		guard let account = NCAccount.current else {return nil}
		return NCDataManager(account: account)
	}()
	
	private func update() {
		navigationItem.rightBarButtonItem?.isEnabled = recipients.count > 0 && !textView.text.isEmpty
	}
	
	private func updateRecipients() {
		toTextView.text = nil
		
		var s = NSAttributedString()
		for id in recipients {
			guard let contact = _recipients[id] else {continue}
			let i = ((contact.name ?? "") + ", ") * [NSAttributedStringKey.foregroundColor: UIColor.caption, NSAttributedStringKey.font: toTextView.font!]
			let rect = i.boundingRect(with: .zero, options: [.usesLineFragmentOrigin], context: nil)
			UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
			i.draw(in: rect)
			let image = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			
			s = s + (NSAttributedString(image: image, font: toTextView.font!) * [NSAttributedStringKey.recipientID: contact.contactID])
		}
		
		s = s * Dictionary(uniqueKeysWithValues: toTextView.typingAttributes.map{(NSAttributedStringKey(rawValue: $0), $1)})
		toTextView.attributedText = s
	}
	
	private func attach(_ attachment: Any) {
		switch attachment {
		case let loadout as NCLoadout:
			guard let data = loadout.data?.data else {return}
			let name = loadout.name?.isEmpty == false ? loadout.name! : NCDatabase.sharedDatabase?.invTypes[Int(loadout.typeID)]?.typeName ?? NSLocalizedString("Unknown", comment: "")
			guard let url = (NCLoadoutRepresentation.dnaURL([(typeID: Int(loadout.typeID), data: data, name: name)]).value as? [URL])?.first else {return}
			let s = name * [NSAttributedStringKey.link: url, NSAttributedStringKey.font: textView.font!] + " " * Dictionary(uniqueKeysWithValues: toTextView.typingAttributes.map{(NSAttributedStringKey(rawValue: $0), $1)})
			textView.textStorage.replaceCharacters(in: textView.selectedRange, with: s)
			textView.selectedRange = NSMakeRange(textView.selectedRange.location + s.length, 0)
			updateConstraints(textView)
			update()
		default:
			break
		}
	}
}
