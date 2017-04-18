//
//  NCMailTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

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

/*class NCMailFetchedResultsNode: FetchedResultsNode<NCMail> {
	let account: NCAccount
	
	init?(account: NCAccount) {
		guard let context = NCCache.sharedCache?.viewContext else {return nil}
		self.account = account
		let request = NSFetchRequest<NCMail>(entityName: "Mail")
		request.predicate = NSPredicate(format: "characterID == %qi", account.characterID)
		request.sortDescriptors = [NSSortDescriptor(key: "folder", ascending: true), NSSortDescriptor(key: "timestamp", ascending: false)]
		
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "folder", cacheName: nil)
		
		super.init(resultsController: controller, sectionNode: NCMailSection.self, objectNode: NCMailRow.self)
	}
}

class NCMailSection: FetchedResultsSectionNode<NCMail> {
	
	required init(section: NSFetchedResultsSectionInfo, objectNode: FetchedResultsObjectNode<NCMail>.Type) {
		super.init(section: section, objectNode: objectNode)
		cellIdentifier = Prototype.NCHeaderTableViewCell.default.reuseIdentifier
		isExpanded = false
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		guard let i = Int(section.name) else {return}
		guard let folder = NCMail.Folder(rawValue: i) else {return}
		cell.titleLabel?.text = folder.name
	}
}

class NCMailRow: FetchedResultsObjectNode<NCMail> {
	
	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .short
		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter
	}()
	
	required init(object: NCMail) {
		super.init(object: object)
		cellIdentifier = Prototype.NCMailTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCMailTableViewCell else {return}
		cell.subjectLabel.text = object.subject
		if let date = object.timestamp as Date? {
			cell.dateLabel.text = NCMailRow.dateFormatter.string(from: date)
		}
		else {
			cell.dateLabel.text = nil
		}
	}
}*/


class NCMailRow: TreeRow {
	
	enum Folder {
		case inbox
		case corporation
		case alliance
		case mailingList(String?)
		case sent
		case unknown
		
		var name: String {
			switch self {
			case .alliance:
				return NSLocalizedString("Alliance", comment: "")
			case .corporation:
				return NSLocalizedString("Corp", comment: "")
			case .inbox:
				return NSLocalizedString("Inbox", comment: "")
			case let .mailingList(name):
				return name ?? NSLocalizedString("Mailing List", comment: "")
			case .sent:
				return NSLocalizedString("Sent", comment: "")
			case .unknown:
				return NSLocalizedString("Unknown", comment: "")
			}
		}
	}
	
	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .short
		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter
	}()
	
	let mail: ESI.Mail.Header
	let recipient: NSAttributedString
	let characterID: Int64
	
	init(mail: ESI.Mail.Header, folder: Folder, contacts: [Int64: NCContact]) {
		self.mail = mail
		characterID = Int64(mail.from!)

		let recipient: String
		if case .sent = folder {
			recipient = mail.recipients?.flatMap({contacts[Int64($0.recipientID)]?.name}).joined(separator: ", ") ?? NSLocalizedString("Unknown", comment: "")
			self.recipient = NSAttributedString(string: recipient)
		}
		else {
			recipient = contacts[Int64(mail.from!)]?.name ?? NSLocalizedString("Unknown", comment: "")
			self.recipient = "[\(folder.name)]" * [NSForegroundColorAttributeName: UIColor.caption, NSFontAttributeName: UIFont.preferredFont(forTextStyle: .footnote)] + " " + recipient
		}
		
//		self.recipient = "[\(folder.name)]" * [NSForegroundColorAttributeName: UIColor.caption, NSFontAttributeName: UIFont.preferredFont(forTextStyle: .footnote)] + " " + recipient
		super.init(prototype: Prototype.NCMailTableViewCell.default, route: Router.Mail.Body(mail: mail))
	}
	
	var image: UIImage?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCMailTableViewCell else {return}
		cell.subjectLabel.text = mail.subject
		cell.object = mail
		if let date = mail.timestamp as Date? {
			cell.dateLabel.text = NCMailRow.dateFormatter.string(from: date)
		}
		else {
			cell.dateLabel.text = nil
		}
		cell.recipientLabel.attributedText = recipient
		cell.iconView.image = image
		
		if image == nil {
			NCDataManager().image(characterID: characterID, dimension: Int(cell.iconView.bounds.size.width)) { result in
				switch result {
				case let .success(value, _):
					self.image = value
				case .failure:
					self.image = UIImage()
				}
				if (cell.object as? ESI.Mail.Header) == self.mail {
					cell.iconView.image = self.image
				}

			}
		}
	}
	
	override var hashValue: Int {
		return mail.mailID?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCMailRow)?.hashValue == hashValue
	}

}
