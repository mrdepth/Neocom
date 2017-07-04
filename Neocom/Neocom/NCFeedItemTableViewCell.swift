//
//  NCFeedItemTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCFeedItemTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
}

extension Prototype {
	enum NCFeedItemTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCFeedItemTableViewCell")
	}
}

class NCFeedItemRow: TreeRow {
	
	let item: RSS.Item
	
	init(item: RSS.Item) {
		self.item = item
		super.init(prototype: Prototype.NCFeedItemTableViewCell.default, route: nil)
	}
	
	var contactName: String?
	lazy var date: String? = {
		guard let date = self.item.updated else {return nil}
		return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
	}()
	
	lazy var subtitle: String? = {
		guard let data = self.item.summary?.data(using: .utf8) else {return nil}
		guard let string =  try? NSAttributedString(data: data,
		                               options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
		                                         NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue],
		                               documentAttributes: nil).string
			else {
				return nil
		}
		return String(string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).characters.prefix(256))
	}()
	
	override func configure(cell: UITableViewCell) {
		
		
		guard let cell = cell as? NCFeedItemTableViewCell else {return}
		cell.titleLabel.text = item.title
		cell.subtitleLabel.text = subtitle
		cell.dateLabel.text = date
	}
	
	override var hashValue: Int {
		return item.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFeedItemRow)?.hashValue == hashValue
	}
}
