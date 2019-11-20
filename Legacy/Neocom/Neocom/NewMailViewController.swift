//
//  NewMailViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class NewMailViewController: UIViewController, View {
	
	typealias Presenter = NewMailPresenter
	lazy var presenter: Presenter! = Presenter(view: self)
	
	struct Input {
		var recipients: [Contact]?
		var subject: String?
		var body: NSAttributedString?
		
		static var blank: Input {
			return Input(recipients: nil, subject: nil, body: nil)
		}
	}

	var input: Input?

	var unwinder: Unwinder?
	
	@IBOutlet weak var searchResultsContainer: UIView!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var toTextView: UITextView!
	@IBOutlet weak var subjectTextView: UITextView!
	@IBOutlet weak var bottomConstraint: NSLayoutConstraint!
	@IBOutlet var accessoryView: UIView!
	@IBOutlet weak var fromLabel: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		presenter.configure()
		
		var label = UILabel(frame: .zero)
		label.attributedText = "To: " * [NSAttributedString.Key.foregroundColor: UIColor.lightText, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline)]
		label.sizeToFit()
		label.frame.origin = CGPoint(x: textView.textContainerInset.left, y: textView.textContainerInset.top)
		
		toTextView.addSubview(label)
		toTextView.textContainer.exclusionPaths = [UIBezierPath(rect: label.frame)]
		toTextView.typingAttributes = [NSAttributedString.Key.foregroundColor: toTextView.textColor!, NSAttributedString.Key.font: toTextView.font!]
		
		label = UILabel(frame: .zero)
		label.attributedText = "Subject: " * [NSAttributedString.Key.foregroundColor: UIColor.lightText, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline)]
		label.sizeToFit()
		label.frame.origin = CGPoint(x: textView.textContainerInset.left, y: textView.textContainerInset.top)
		
		subjectTextView.addSubview(label)
		subjectTextView.textContainer.exclusionPaths = [UIBezierPath(rect: label.frame)]
		
		textView.inputAccessoryView = accessoryView
		textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.caption]
		textView.typingAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body), NSAttributedString.Key.foregroundColor: UIColor.white]

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		presenter.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presenter.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		presenter.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		presenter.viewDidDisappear(animated)
	}
	
	@objc private func keyboardWillChangeFrame(_ note: Notification) {
		guard var finalFrame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {return}
		finalFrame = view.convert(finalFrame, from: nil)
		
		bottomConstraint.constant = max(view.bounds.maxY - finalFrame.minY, 0)
		view.layoutIfNeeded()
	}
	
	@IBAction func onTap(_ sender: UITapGestureRecognizer) {
		let p = sender.location(in: scrollView)
		if p.y > textView.frame.maxY {
			textView.becomeFirstResponder()
		}
	}
	
	var searchResultsViewController: ContactsSearchResultsViewController?
}

extension NewMailViewController: UITextViewDelegate {
	
	func textViewDidChange(_ textView: UITextView) {
		if textView == toTextView {
			let n: Int = toTextView.attributedText.length
			var s: String?
			if n > 1 {
				var range = NSRange(location: 0, length: n)
				toTextView.attributedText.attributes(at: n - 1, longestEffectiveRange: &range, in: range)
				if range.length > 0 {
					s = toTextView.attributedText.attributedSubstring(from: range).string
				}
			}
			presenter.searchContacts(with: s ?? toTextView.text)
		}
	}
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		if textView == toTextView {
			let p: CGPoint
			if #available(iOS 11.0, *) {
				p = CGPoint(x: 0, y: -scrollView.adjustedContentInset.top)
			} else {
				p = CGPoint(x: 0, y: -scrollView.contentInset.top)
			}
			scrollView.setContentOffset(p, animated: true)
			
			if searchResultsViewController == nil {
				searchResultsViewController = try! ContactsSearchResults.default.instantiate(self).get()
				searchResultsViewController!.view.frame = searchResultsContainer.bounds
				addChild(searchResultsViewController!)
				searchResultsContainer.addSubview(searchResultsViewController!.view)
				searchResultsViewController!.didMove(toParent: self)
			}
			
			scrollView.isScrollEnabled = false
			UIView.animate(withDuration: 0.15) {
				self.searchResultsContainer.alpha = 1.0
			}
		}
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		if textView == toTextView {
			scrollView.isScrollEnabled = true
			UIView.animate(withDuration: 0.15) {
				self.searchResultsContainer.alpha = 0.0
			}
		}
	}
	
	func textViewDidChangeSelection(_ textView: UITextView) {
		if textView == self.textView {
			textView.typingAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body), NSAttributedString.Key.foregroundColor: UIColor.white]
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
				let s = textView.attributedText.copy() as? NSAttributedString
				s?.enumerateAttributes(in: range, options: [], using: { (attributes, _, _) in
					//					guard let attachment = attributes[NSAttachmentAttributeName] as? NSTextAttachment else {return}
					guard let recipientID = attributes[.recipientID] as? Int64 else {return}
					presenter.removeRecipient(with: recipientID)
				})
				return false
			}
		}
		else {
			if textView.attributedText.length > range.location && textView.attributedText.containsAttachments(in: NSMakeRange(range.location, 1)) {
				return false
			}
		}
		return true
	}
}

extension NewMailViewController: ContactsSearchResultsViewControllerDelegate {
	func contactsSearchResultsViewController(_ controller: ContactsSearchResultsViewController, didSelect contact: Contact) {
		presenter.didSelectContact(contact)
	}
}
