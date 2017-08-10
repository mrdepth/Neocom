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
		static let `default` = Prototype(nib: UINib(nibName: "NCMailTableViewCell", bundle: nil), reuseIdentifier: "NCMailTableViewCell")
	}
}


class NCMailRow: TreeRow {
	
	/*enum Folder {
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
	}*/
	
	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .none
		dateFormatter.timeStyle = .short
//		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter
	}()
	
	let mail: ESI.Mail.Header
	let contacts: [Int64: NCContact]
	let label: ESI.Mail.MailLabelsAndUnreadCounts.Label
	
	lazy var recipient: String = {
		if self.mail.from == Int(self.dataManager.characterID) {
			return self.mail.recipients?.flatMap({self.contacts[Int64($0.recipientID)]?.name}).joined(separator: ", ") ?? NSLocalizedString("Unknown", comment: "")
		}
		else {
			return self.contacts[Int64(self.mail.from!)]?.name ?? NSLocalizedString("Unknown", comment: "")
		}
	}()
	
	let characterID: Int64
	let cacheRecord: NCCacheRecord?
	let dataManager: NCDataManager
	
	init(mail: ESI.Mail.Header, label: ESI.Mail.MailLabelsAndUnreadCounts.Label, contacts: [Int64: NCContact], cacheRecord: NCCacheRecord?, dataManager: NCDataManager) {
		self.mail = mail
		self.cacheRecord = cacheRecord
		self.label = label
		self.contacts = contacts
		self.dataManager = dataManager
		characterID = Int64(mail.from!)

		super.init(prototype: Prototype.NCMailTableViewCell.default, route: Router.Mail.Body(mail: mail))
	}
	
	var image: UIImage?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCMailTableViewCell else {return}

		cell.object = mail
		if let date = mail.timestamp as Date? {
			cell.dateLabel.text = NCMailRow.dateFormatter.string(from: date)
		}
		else {
			cell.dateLabel.text = nil
		}
		cell.recipientLabel.text = recipient
		cell.recipientLabel.textColor = mail.isRead == true ? .lightText : .white
		cell.subjectLabel.text = mail.subject
		cell.subjectLabel.textColor = cell.recipientLabel.textColor
		
		cell.iconView.image = image
		
		if image == nil {
			dataManager.image(characterID: characterID, dimension: Int(cell.iconView.bounds.size.width)) { result in
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
