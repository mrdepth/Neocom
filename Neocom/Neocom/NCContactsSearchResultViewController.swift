//
//  NCContactsSearchResultViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCContactRow: TreeRow {
	
	let contact: NCContact?
	let dataManager: NCDataManager
	var image: UIImage?
	
	init(prototype: Prototype = Prototype.NCDefaultTableViewCell.compact, contact: NCContact?, dataManager: NCDataManager) {
		self.contact = contact
		self.dataManager = dataManager
		super.init(prototype: prototype)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
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

protocol NCContactsSearchResultViewControllerDelegate: NSObjectProtocol {
	func contactsSearchResultsViewController(_ controller: NCContactsSearchResultViewController, didSelect contact: NCContact)
}

class NCContactsSearchResultViewController: UITableViewController, TreeControllerDelegate {
	
	@IBOutlet var treeController: TreeController!
	weak var delegate: NCContactsSearchResultViewControllerDelegate?
	
//	var contacts: [ESI.Mail.Recipient.RecipientType: [Int64: NCContact]] = [:] {
	var contacts: [NCContact] = [] {
		didSet {
			var names: [ESI.Mail.Recipient.RecipientType: [NCContact]] = [:]
			
			for contact in contacts {
				guard let recipientType = contact.recipientType else {continue}
				var array = names[recipientType] ?? []
				array.append(contact)
				names[recipientType] = array
			}

			
			let dataManager = NCDataManager(account: NCAccount.current)
			let titles = [ESI.Mail.Recipient.RecipientType.alliance: NSLocalizedString("Alliances", comment: ""),
			              ESI.Mail.Recipient.RecipientType.corporation: NSLocalizedString("Corporations", comment: ""),
			              ESI.Mail.Recipient.RecipientType.character: NSLocalizedString("Characters", comment: "")]
			let identifiers = [ESI.Mail.Recipient.RecipientType.character: "0",
			                   ESI.Mail.Recipient.RecipientType.corporation: "1",
			                   ESI.Mail.Recipient.RecipientType.alliance: "2"]
			var sections = [DefaultTreeSection]()
			for (key, value) in names {
				let rows = value.map { NCContactRow(contact: $0, dataManager: dataManager) }.sorted { ($0.contact?.name ?? "") < ($1.contact?.name ?? "") }
				let section = DefaultTreeSection(nodeIdentifier: identifiers[key], title: titles[key], children: rows)
				sections.append(section)
			}
			sections.sort { ($0.0.nodeIdentifier ?? "Z") < ($0.1.nodeIdentifier ?? "Z") }
			
			UIView.performWithoutAnimation {
				if let root = treeController.content {
					root.children = sections
				}
				else {
					let root = TreeNode()
					root.children = sections
					treeController.content = root
				}
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCHeaderTableViewCell.default])
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		tableView.backgroundColor = UIColor.cellBackground
		tableView.separatorColor = UIColor.separator
	}
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? NCContactRow, let contact = node.contact else {return}
		delegate?.contactsSearchResultsViewController(self, didSelect: contact)
	}
}
