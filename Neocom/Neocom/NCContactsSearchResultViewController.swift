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
	
	let contactID: Int64
	let name: String
	let category: ESI.Search.SearchCategories
	let dataManager: NCDataManager
	var image: UIImage?
	
	init(contactID: Int64, name: String, category: ESI.Search.SearchCategories, dataManager: NCDataManager) {
		self.contactID = contactID
		self.name = name
		self.category = category
		self.dataManager = dataManager
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.object = contactID
		cell.titleLabel?.text = name
		
		if let image = image {
			cell.iconView?.image = image
		}
		else {
			cell.iconView?.image = nil
			
			let completionHandler = { (result: NCCachedResult<UIImage>) -> Void in
				switch result {
				case let .success(value):
					self.image = value.value
					if (cell.object as? Int64) == self.contactID {
						cell.iconView?.image = self.image
					}
				case .failure:
					self.image = UIImage()
				}
			}
			
			switch category {
			case .alliance:
				dataManager.image(allianceID: contactID, dimension: Int(cell.iconView!.bounds.width), completionHandler: completionHandler)
			case .corporation:
				dataManager.image(corporationID: contactID, dimension: Int(cell.iconView!.bounds.width), completionHandler: completionHandler)
			case .character:
				dataManager.image(characterID: contactID, dimension: Int(cell.iconView!.bounds.width), completionHandler: completionHandler)
			default:
				break
			}
		}
	}
	
	override var hashValue: Int {
		return Int(contactID)
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCContactRow)?.contactID == contactID
	}
}

protocol NCContactsSearchResultViewControllerDelegate: NSObjectProtocol {
	func contactsSearchResultsViewController(_ controller: NCContactsSearchResultViewController, didSelect contact: (contactID: Int64, name: String, category: ESI.Search.SearchCategories))
}

class NCContactsSearchResultViewController: UITableViewController, TreeControllerDelegate {
	
	@IBOutlet var treeController: TreeController!
	weak var delegate: NCContactsSearchResultViewControllerDelegate?
	
	var contacts: [ESI.Search.SearchCategories: [Int64: String]] = [:] {
		didSet {
			let dataManager = NCDataManager(account: NCAccount.current)
			let titles = [ESI.Search.SearchCategories.alliance: NSLocalizedString("Alliances", comment: ""),
			              ESI.Search.SearchCategories.corporation: NSLocalizedString("Corporations", comment: ""),
			              ESI.Search.SearchCategories.character: NSLocalizedString("Characters", comment: "")]
			let identifiers = [ESI.Search.SearchCategories.character: "0",
			                   ESI.Search.SearchCategories.corporation: "1",
			                   ESI.Search.SearchCategories.alliance: "2"]
			var sections = [DefaultTreeSection]()
			for (key, value) in contacts {
				let rows = value.map { NCContactRow(contactID: $0.key, name: $0.value, category: key, dataManager: dataManager) }.sorted { $0.0.name < $0.1.name }
				let section = DefaultTreeSection(nodeIdentifier: identifiers[key], title: titles[key], children: rows)
				sections.append(section)
			}
			sections.sort { ($0.0.nodeIdentifier ?? "Z") < ($0.1.nodeIdentifier ?? "Z") }
			
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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCHeaderTableViewCell.default])
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
	}
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? NCContactRow else {return}
		delegate?.contactsSearchResultsViewController(self, didSelect: (contactID: node.contactID, name: node.name, category: node.category))
	}
}
