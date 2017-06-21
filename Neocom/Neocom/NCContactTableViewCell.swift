//
//  NCContactTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

typealias NCContactTableViewCell = NCDefaultTableViewCell

extension Prototype {
	enum NCContactTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCContactTableViewCell", bundle: nil), reuseIdentifier: "NCContactTableViewCell")
		static let compact = Prototype(nib: UINib(nibName: "NCContactCompactTableViewCell", bundle: nil), reuseIdentifier: "NCContactCompactTableViewCell")
	}
}

class NCContactRow: TreeRow {
	
	let contact: NCContact?
	let dataManager: NCDataManager
	var image: UIImage?
	
	init(prototype: Prototype = Prototype.NCContactTableViewCell.compact, contact: NCContact?, dataManager: NCDataManager) {
		self.contact = contact
		self.dataManager = dataManager
		super.init(prototype: prototype)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCContactTableViewCell else {return}
		cell.object = contact
		cell.titleLabel?.text = contact?.name ?? NSLocalizedString("Unknown", comment: "")
		
		if let image = image {
			cell.iconView?.image = image
		}
		else {
			cell.iconView?.image = nil
			
			guard let contact = self.contact else {return}
			
			let completionHandler = { (result: NCCachedResult<UIImage>) -> Void in
				switch result {
				case let .success(value):
					self.image = value.value
					if (cell.object as? NCContact) == self.contact {
						cell.iconView?.image = self.image
					}
				case .failure:
					self.image = UIImage()
				}
			}
			
			switch contact.recipientType ?? .character {
			case .alliance:
				dataManager.image(allianceID: contact.contactID, dimension: Int(cell.iconView!.bounds.width), completionHandler: completionHandler)
			case .corporation:
				dataManager.image(corporationID: contact.contactID, dimension: Int(cell.iconView!.bounds.width), completionHandler: completionHandler)
			case .character:
				dataManager.image(characterID: contact.contactID, dimension: Int(cell.iconView!.bounds.width), completionHandler: completionHandler)
			default:
				break
			}
		}
	}
	
	override var hashValue: Int {
		return contact?.hashValue ?? super.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCContactRow)?.hashValue == hashValue
	}
}
