//
//  NCMailViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCMailViewController: UIViewController, UITextViewDelegate {
	
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var toTextField: UITextField!
	@IBOutlet weak var subjectTextField: UITextField!
	@IBOutlet weak var bottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var heightConstraint: NSLayoutConstraint!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillHide, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		updateConstraints()
	}
	
	@IBAction func onTap(_ sender: UITapGestureRecognizer) {
		let p = sender.location(in: scrollView)
		if p.y > textView.frame.maxY {
			textView.becomeFirstResponder()
		}
	}
	
	@IBAction func onChangeContact(_ sender: Any) {
		scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.contentInset.top), animated: true)
		search(toTextField.text ?? "")
	}
	
	//MARK: - UITextViewDelegate
	
	
	func textViewDidChange(_ textView: UITextView) {
		updateConstraints()
		textView.layoutIfNeeded()
	}
	
	private func updateConstraints() {
		let size = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
		heightConstraint.constant = size.height.rounded(.up)
	}
	
	@objc private func keyboardWillChangeFrame(_ note: Notification) {
		guard var finalFrame = note.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect else {return}
		finalFrame = view.convert(finalFrame, from: nil)
		
		bottomConstraint.constant = max(view.bounds.maxY - finalFrame.minY, 0)
		view.layoutIfNeeded()
		//		print("\(scrollView.contentInset)")
	}

	private lazy var gate = NCGate()
	private lazy var dataManager: NCDataManager? = {
		guard let account = NCAccount.current else {return nil}
		return NCDataManager(account: account)
	}()

	private func search(_ string: String) {
		let string = string.trimmingCharacters(in: CharacterSet.whitespaces)
		guard string.utf8.count >= 3 else {return}
		guard let dataManager = dataManager else {return}
		
		gate.perform {
			let dispatchGroup = DispatchGroup()
			
			dispatchGroup.enter()
			
			dataManager.searchNames(string, categories: [.character, .corporation, .alliance], strict: false) { result in
				defer {dispatchGroup.leave()}
				
				switch result {
				case let .success(value):
					break
				case .failure:
					break
				}
			}
			
			dispatchGroup.wait()
		}
	}
}
