//
//  NCMailTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCMailTableViewCell: NCTableViewCell {
	@IBOutlet weak var recipientLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var subjectLabel: UILabel!
	@IBOutlet weak var iconView: UIImageView!
	
}

extension Prototype {
	enum NCMailTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCMailTableViewCell")
	}
}

class NCMailRow: TreeRow {
	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .short
		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter
	}()
	let mail: ESI.Mail.Header
	
	init(mail: ESI.Mail.Header) {
		self.mail = mail
		super.init(prototype: Prototype.NCMailTableViewCell.default)
	}
	
	override var hashValue: Int {
		return mail.mailID?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCMailRow)?.hashValue == hashValue
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCMailTableViewCell else {return}
		cell.subjectLabel.text = mail.subject
		if let date = mail.timestamp {
			cell.dateLabel.text = NCMailRow.dateFormatter.string(from: date)
		}
		else {
			cell.dateLabel.text = nil
		}
	}

}
