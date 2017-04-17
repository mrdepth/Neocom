//
//  NCNewMailViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCNewMailViewController: UIViewController, UITextViewDelegate, NCContactsSearchResultViewControllerDelegate {
	
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var toTextView: UITextView!
	@IBOutlet weak var subjectTextView: UITextView!
	@IBOutlet weak var bottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var heightConstraint: NSLayoutConstraint!
	@IBOutlet var accessoryView: UIView!
	
	private lazy var searchResultViewController: NCContactsSearchResultViewController? = {
		let controller = self.childViewControllers.first as? NCContactsSearchResultViewController
		controller?.delegate = self
		return controller
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		update()
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillHide, object: nil)
		
		var label = UILabel(frame: .zero)
		label.attributedText = "To: " * [NSForegroundColorAttributeName: UIColor.lightText, NSFontAttributeName: UIFont.preferredFont(forTextStyle: .subheadline)]
		label.sizeToFit()
		label.frame.origin = CGPoint(x: textView.textContainerInset.left, y: textView.textContainerInset.top)
		
		toTextView.addSubview(label)
		toTextView.textContainer.exclusionPaths = [UIBezierPath(rect: label.frame)]
		
		label = UILabel(frame: .zero)
		label.attributedText = "Subject: " * [NSForegroundColorAttributeName: UIColor.lightText, NSFontAttributeName: UIFont.preferredFont(forTextStyle: .subheadline)]
		label.sizeToFit()
		label.frame.origin = CGPoint(x: textView.textContainerInset.left, y: textView.textContainerInset.top)

		subjectTextView.addSubview(label)
		subjectTextView.textContainer.exclusionPaths = [UIBezierPath(rect: label.frame)]
		
		textView.inputAccessoryView = accessoryView

	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateConstraints(textView)
		updateConstraints(toTextView)
		updateConstraints(subjectTextView)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
//		updateConstraints(textView)
	}
	
	@IBAction func onTap(_ sender: UITapGestureRecognizer) {
		let p = sender.location(in: scrollView)
		if p.y > textView.frame.maxY {
			textView.becomeFirstResponder()
		}
	}
	
	@IBAction func onSend(_ sender: Any) {
		let recipients = contacts.flatMap { contact -> ESI.Mail.NewMail.Recipient? in
			let recipient = ESI.Mail.NewMail.Recipient()
			recipient.recipientID = Int(contact.contactID)
			switch contact.category {
			case .alliance:
				recipient.recipientType = .alliance
			case .corporation:
				recipient.recipientType = .corporation
			case .character:
				recipient.recipientType = .character
			default:
				return nil
			}
			return recipient
		}
		
		dataManager?.sendMail(body: textView.text, subject: subjectTextView.text, recipients: recipients, completionHandler: { result in
			switch result {
			case .success:
				break
			case let .failure(error):
				break
//				UIAlertController(
			}
		})
	}
	//MARK: - UITextViewDelegate
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		print("\(scrollView.contentOffset)")
	}
	
	
	func textViewDidChange(_ textView: UITextView) {
		updateConstraints(textView)

		//textView.layoutIfNeeded()
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
					guard let contactID = attributes["contactID"] as? Int64 else {return}
					guard let i = contacts.index(where: {$0.contactID == contactID}) else {return}
					contacts.remove(at: i)
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
	
	private var contacts: [(contactID: Int64, name: String, category: ESI.Search.SearchCategories)] = []
	
	func contactsSearchResultsViewController(_ controller: NCContactsSearchResultViewController, didSelect contact: (contactID: Int64, name: String, category: ESI.Search.SearchCategories)) {
		guard contacts.first(where: {$0.contactID == contact.contactID}) == nil else {return}
		
		contacts.append(contact)
		toTextView.text = nil
		
		var s = NSAttributedString()
		for contact in contacts {
			let i = (contact.name + ", ") * [NSForegroundColorAttributeName: UIColor.caption, NSFontAttributeName: textView.font!]
			let rect = i.boundingRect(with: .zero, options: [.usesLineFragmentOrigin], context: nil)
			UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
			i.draw(in: rect)
			let image = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			
			s = s + (NSAttributedString(image: image, font: toTextView.font!) * ["contactID": contact.contactID])
		}
		s = s * textView.typingAttributes
		toTextView.attributedText = s
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

	private lazy var gate = NCGate()
	private lazy var dataManager: NCDataManager? = {
		guard let account = NCAccount.current else {return nil}
		return NCDataManager(account: account)
	}()

	private func search(_ string: String) {
		let string = string.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		guard let dataManager = dataManager, string.utf8.count >= 3 else {
			searchResultViewController?.contacts = [:]
			return
		}
		
		gate.perform {
			let dispatchGroup = DispatchGroup()
			
			dispatchGroup.enter()
			
			dataManager.searchNames(string, categories: [.character, .corporation, .alliance], strict: false) { [weak self] result in
				defer {dispatchGroup.leave()}
				guard let strongSelf = self else {return}
				
				switch result {
				case let .success(value):
					var result: [ESI.Search.SearchCategories: [Int64: String]] = [:]
					value.value.forEach {result[ESI.Search.SearchCategories(rawValue: $0.key) ?? .character] = $0.value}
					strongSelf.searchResultViewController?.contacts = result
				case .failure:
					break
				}
			}
			
			dispatchGroup.wait()
		}
	}
	
	private func update() {
		navigationItem.rightBarButtonItem?.isEnabled = contacts.count > 0 && !textView.text.isEmpty
	}
}
