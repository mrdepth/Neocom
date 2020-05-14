//
//  NCContactTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData
import Futures

typealias NCContactTableViewCell = NCDefaultTableViewCell

extension Prototype {
	enum NCContactTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCContactTableViewCell", bundle: nil), reuseIdentifier: "NCContactTableViewCell")
		static let compact = Prototype(nib: UINib(nibName: "NCContactCompactTableViewCell", bundle: nil), reuseIdentifier: "NCContactCompactTableViewCell")
		static let attribute = Prototype(nib: UINib(nibName: "NCContactAttributeTableViewCell", bundle: nil), reuseIdentifier: "NCContactAttributeTableViewCell")
		
	}
}

class NCContactRow: TreeRow {
	
	lazy var contact: NCContact? = {
		guard let contactID = self.contactID else {return nil}
		return (try? NCCache.sharedCache?.viewContext.existingObject(with: contactID)) as? NCContact
	}()
	
	let contactID: NSManagedObjectID?
	let dataManager: NCDataManager
	var image: UIImage?
	
	init(prototype: Prototype = Prototype.NCContactTableViewCell.compact, contact: NSManagedObjectID?, dataManager: NCDataManager, route: Route? = nil, accessoryButtonRoute: Route? = nil) {
		self.contactID = contact
		self.dataManager = dataManager
		super.init(prototype: prototype, route: route, accessoryButtonRoute: accessoryButtonRoute)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCContactTableViewCell else {return}
		cell.object = contact
		cell.titleLabel?.text = contact?.name ?? NSLocalizedString("Unknown", comment: "")
		
		if let image = image {
			cell.iconView?.image = image
		}
		else {
			cell.iconView?.image = UIImage()
			
			guard let contact = self.contact else {return}
			
			let image: Future<CachedValue<UIImage>>?
			
			switch contact.recipientType ?? .character {
			case .alliance:
				image = dataManager.image(allianceID: contact.contactID, dimension: Int(cell.iconView!.bounds.width))
			case .corporation:
				image = dataManager.image(corporationID: contact.contactID, dimension: Int(cell.iconView!.bounds.width))
			case .character:
				image = dataManager.image(characterID: contact.contactID, dimension: Int(cell.iconView!.bounds.width))
			default:
				image = nil
			}
			image?.then(on: .main) { value in
				self.image = value.value ?? UIImage()
				if (cell.object as? NCContact) == self.contact {
					cell.iconView?.image = self.image
				}
			}
		}
	}
	
	override var hash: Int {
		return contactID?.hashValue ?? super.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCContactRow)?.hashValue == hashValue
	}
}
