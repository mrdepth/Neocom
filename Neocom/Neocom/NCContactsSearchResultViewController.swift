//
//  NCContactsSearchResultViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI


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
		
		tableView.register([Prototype.NCContactTableViewCell.compact,
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
