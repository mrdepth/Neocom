//
//  MailBodyViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/2/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures
import EVEAPI

class MailBodyViewController: UIViewController, ContentProviderView {

	@IBOutlet weak var fromLabel: UILabel!
	@IBOutlet weak var toLabel: UILabel!
	@IBOutlet weak var subjectLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var textView: UITextView!

	typealias Presenter = MailBodyPresenter
	lazy var presenter: Presenter! = Presenter(view: self)
	var input: ESI.Mail.Header?
	
	var unwinder: Unwinder?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		presenter.configure()
		textView.delegate = self
		textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.caption]
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

	func present(_ content: Presenter.Presentation, animated: Bool) -> Future<Void> {
		fromLabel.text = content.from
		toLabel.text = content.to
		subjectLabel.text = content.subject
		dateLabel.text = content.date
		textView.attributedText = content.body
		return .init(())
	}
	
	func fail(_ error: Error) {
		textView.text = error.localizedDescription
	}
	
	@IBAction func onReply(_ sender: Any) {
		presenter.onReply()
	}
}

extension MailBodyViewController: UITextViewDelegate {
	func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
		if UIApplication.shared.canOpenURL(URL) {
			UIApplication.shared.open(URL, options: [:], completionHandler: nil)
		}
		return false
	}
//	func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
//		if UIApplication.shared.canOpenURL(URL) {
//			UIApplication.shared.open(URL, options: [:], completionHandler: nil)
//		}
//		return false
//	}
}
