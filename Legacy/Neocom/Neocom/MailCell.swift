//
//  MailCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/2/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import EVEAPI

class MailCell: RowCell {
	@IBOutlet weak var recipientLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var subjectLabel: UILabel!
	@IBOutlet weak var iconView: UIImageView!

}

extension Prototype {
	enum MailCell {
		static let `default` = Prototype(nib: UINib(nibName: "MailCell", bundle: nil), reuseIdentifier: "MailCell")
	}
}

extension Tree.Item {
	class MailRow: Row<ESI.Mail.Header> {
		override var prototype: Prototype? { return Prototype.MailCell.default }
		var label: ESI.Mail.MailLabelsAndUnreadCounts.Label
		var contacts: [Int64: Contact]
		var characterID: Int64
		var image: UIImage?
		var api: API
		
		init(_ content: ESI.Mail.Header, contacts: [Int64: Contact], label: ESI.Mail.MailLabelsAndUnreadCounts.Label, characterID: Int64, api: API) {
//			self.header = header
			self.contacts = contacts
			self.label = label
			self.characterID = characterID
			self.api = api
			super.init(content)
		}
		
		lazy var date: String? = {
			return content.timestamp.map {
				let dateFormatter = DateFormatter()
				dateFormatter.dateStyle = .none
				dateFormatter.timeStyle = .short
				return dateFormatter.string(from: $0)
			}
		}()
		
		lazy var recipient: String = {
			
			if content.from == Int(characterID) {
				return content.recipients?.compactMap({contacts[Int64($0.recipientID)]?.name}).joined(separator: ", ") ?? NSLocalizedString("Unknown", comment: "")
			}
			else {
				return contacts[Int64(content.from!)]?.name ?? NSLocalizedString("Unknown", comment: "")
			}
		}()
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			guard let cell = cell as? MailCell else {return}
			
			cell.dateLabel.text = date
			cell.recipientLabel.text = recipient
			cell.recipientLabel.textColor = content.isRead == true ? .lightText : .white
			cell.subjectLabel.text = content.subject
			cell.subjectLabel.textColor = cell.recipientLabel.textColor
			cell.iconView.image = image
			
			if let from = content.from, image == nil {
				api.image(characterID: Int64(from), dimension: Int(cell.iconView.bounds.size.width), cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self, weak treeController] result in
					guard let strongSelf = self else {return}
					strongSelf.image = result.value
					if let cell = treeController?.cell(for: strongSelf) as? MailCell {
						cell.iconView.image = strongSelf.image
					}
				}.catch(on: .main) { [weak self] _ in
					self?.image = UIImage()
				}
			}
		}
	}
}
