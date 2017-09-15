//
//  NCEventViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import WebKit
import CoreData

class NCEventViewController: UIViewController {
	
	@IBOutlet weak var fromLabel: UILabel!
	@IBOutlet weak var subjectLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!
	@IBOutlet weak var textView: UITextView!
	
	var event: ESI.Calendar.Summary?
	
	private var contacts: [Int64: NCContact]?
	private var body: NSAttributedString?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard let event = self.event, let account = NCAccount.current, let eventID = event.eventID else {return}
		
		dateLabel.text = DateFormatter.localizedString(from: event.eventDate!, dateStyle: .medium, timeStyle: .medium)
		subjectLabel.text = event.title
		
		
		let dataManager = NCDataManager(account: account)
		
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
		
		dataManager.calendarEventDetails(eventID: Int64(eventID)) { result in
			defer {progress.finish()}
			
			switch result {
			case let .success(value, _):
				let font = self.textView.font ?? UIFont.preferredFont(forTextStyle: .footnote)
				let html = "<body style=\"color:white;font-size: \(font.pointSize);font-family: '\(font.familyName)';\">\(value.text)</body>"

				let s = try? NSAttributedString(data: html.data(using: .utf8) ?? Data(),
				                                options: [.documentType : NSAttributedString.DocumentType.html,
				                                          .characterEncoding: String.Encoding.utf8.rawValue,
				                                          .defaultAttributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .footnote)]],
				                                documentAttributes: nil)
				self.textView.attributedText = s
				self.body = s
				self.fromLabel.text = value.ownerName
				if value.duration > 0 {
					self.durationLabel.text = NSLocalizedString("Duration", comment: "") + ": \(NCTimeIntervalFormatter.localizedString(from: TimeInterval(value.duration * 60), precision: .minutes))"
				}
			case let .failure(error):
				self.textView.text = error.localizedDescription
			}
			
			let size = self.textView.sizeThatFits(CGSize(width: self.textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
			let heightConstraint = self.textView.constraints.first {$0.firstAttribute == .height && ($0.firstItem as? UITextView) == self.textView}
			heightConstraint?.constant = max(size.height.rounded(.up), 32)
		}
	}
	
	
}
