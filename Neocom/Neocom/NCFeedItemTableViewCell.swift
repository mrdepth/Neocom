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
	let subtitle: String?
	
	private static let tagRegexp = try! NSRegularExpression(pattern: "<.*?>", options: [])

	init(item: RSS.Item) {
		self.item = item
		
		if let summary = (self.item.summary as NSString?)?.mutableCopy() as? NSMutableString {
			NCFeedItemRow.tagRegexp.replaceMatches(in: summary, options: [], range: NSMakeRange(0, summary.length), withTemplate: "")
			if let data = (summary as String).data(using: .utf8),
				let string =  try? NSAttributedString(data: data,
			                                      options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue],
			                                      documentAttributes: nil).string {
				subtitle = String(string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).characters.prefix(256))
			}
			else {
				subtitle = nil
			}
		}
		else {
			subtitle = nil
		}

		super.init(prototype: Prototype.NCFeedItemTableViewCell.default, route: Router.RSS.Item(item: item))
	}
	
	var contactName: String?
	lazy var date: String? = {
		guard let date = self.item.updated else {return nil}
		return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
	}()
	
	lazy var isVisited: Bool = {
		guard let url = self.item.link else {return false}
		guard let link: NCCacheVisitedLink = NCCache.sharedCache?.viewContext.fetch("VisitedLink", where: "url == %@", url.absoluteString.lowercased()) else {return false}
		return true
	}()
	
	
	override func configure(cell: UITableViewCell) {
		
		guard let cell = cell as? NCFeedItemTableViewCell else {return}
		cell.titleLabel.text = item.title
		cell.subtitleLabel.text = subtitle
		cell.dateLabel.text = date
		cell.titleLabel.textColor = isVisited ? .lightText : .white
	}
	
	override var hashValue: Int {
		return item.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFeedItemRow)?.hashValue == hashValue
	}
}
