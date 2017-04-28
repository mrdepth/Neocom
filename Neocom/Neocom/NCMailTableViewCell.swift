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
	let contacts: [Int64: NCContact]
	let folder: Folder
	
	lazy var recipient: NSAttributedString = {
		let recipient: String
		if case .sent = self.folder {
			recipient = self.mail.recipients?.flatMap({self.contacts[Int64($0.recipientID)]?.name}).joined(separator: ", ") ?? NSLocalizedString("Unknown", comment: "")
			return NSAttributedString(string: recipient)
		}
		else {
			recipient = self.contacts[Int64(self.mail.from!)]?.name ?? NSLocalizedString("Unknown", comment: "")
			if case .mailingList = self.folder {
				return "[\(self.folder.name)]" * [NSForegroundColorAttributeName: UIColor.caption, NSFontAttributeName: UIFont.preferredFont(forTextStyle: .footnote)] + " " + recipient
			}
			else {
				return NSAttributedString(string: recipient)
			}
			
		}
	}()
	
	let characterID: Int64
	let cacheRecord: NCCacheRecord?
	
	init(mail: ESI.Mail.Header, folder: Folder, contacts: [Int64: NCContact], cacheRecord: NCCacheRecord?) {
		self.mail = mail
		self.cacheRecord = cacheRecord
		self.folder = folder
		self.contacts = contacts
		characterID = Int64(mail.from!)

		
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
		cell.recipientLabel.attributedText = mail.isRead == true ? recipient * [NSForegroundColorAttributeName: UIColor.lightText] : recipient
		cell.subjectLabel.textColor = mail.isRead == true ? UIColor.lightText : UIColor.white
		
		cell.iconView.image = image
//		cell.recipientLabel.font = mail.isRead == true ? UIFont.systemFont(ofSize: cell.recipientLabel.font.pointSize) : UIFont.boldSystemFont(ofSize: cell.recipientLabel.font.pointSize)
//		cell.subjectLabel.font = mail.isRead == true ? UIFont.systemFont(ofSize: cell.subjectLabel.font.pointSize) : UIFont.boldSystemFont(ofSize: cell.subjectLabel.font.pointSize)
		
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

class NCDraftsNode: FetchedResultsNode<NCMailDraft> {
	init?() {
		guard let context = NCStorage.sharedStorage?.viewContext else {return nil}
		let request = NSFetchRequest<NCMailDraft>(entityName: "MailDraft")
		request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		super.init(resultsController: controller, objectNode: NCDraftRow.self)
	}
}

class NCDraftRow: FetchedResultsObjectNode<NCMailDraft>, TreeNodeRoutable {
	
	let route: Route?
	let accessoryButtonRoute: Route? = nil

	required init(object: NCMailDraft) {
		route = Router.Mail.NewMessage(draft: object)
		super.init(object: object)
		cellIdentifier = Prototype.NCMailTableViewCell.default.reuseIdentifier
	}
	
	private var recipient: String?
	private var image: UIImage?

	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCMailTableViewCell else {return}
		cell.subjectLabel.textColor = .white

		if object.subject?.isEmpty == false {
			cell.subjectLabel.text = object.subject
		}
		else if let s = object.body?.string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), !s.isEmpty {
			cell.subjectLabel.text = s
		}
		else {
			cell.subjectLabel.text = NSLocalizedString("No Subject", comment: "")
		}
		cell.object = object
		cell.recipientLabel.text = self.recipient
		cell.iconView.image = nil
		cell.dateLabel.text = nil
		if recipient == nil, let to = object.to, !to.isEmpty {
			NCDataManager(account: NCAccount.current).contacts(ids: Set(to)) { result in
				let recipient = to.flatMap({result[$0]?.name}).joined(separator: ", ")
				self.recipient = recipient
				if (cell.object as? NCMailDraft) == self.object {
					cell.recipientLabel.text = self.recipient
				}
				
				if let (_, contact) = result.first(where: {$0.value.recipientType == .character || $0.value.recipientType == .corporation}) {
					
					func handler(result: NCCachedResult<UIImage>) {
						switch result {
						case let .success(value, _):
							self.image = value
						case .failure:
							self.image = UIImage()
						}
						if (cell.object as? NCMailDraft) == self.object {
							cell.iconView.image = self.image
						}
					}
					
					if contact.recipientType == .character {
						NCDataManager().image(characterID: contact.contactID, dimension: Int(cell.iconView.bounds.size.width), completionHandler: handler)
					}
					else {
						NCDataManager().image(corporationID: contact.contactID, dimension: Int(cell.iconView.bounds.size.width), completionHandler: handler)
					}
				}
			}
		}
	}
}
