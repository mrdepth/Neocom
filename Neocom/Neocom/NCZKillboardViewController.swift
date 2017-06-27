//
//  NCZKillboardViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

fileprivate protocol NCZKillboardFilterRow: class {
	var handler: NCActionHandler? {get set}
}

extension NCZKillboardFilterRow {
	
	func configureAccessoryButton(for cell: UITableViewCell) {
		let button = UIButton(type: .system)
		button.setImage(#imageLiteral(resourceName: "clear"), for: .normal)
		button.sizeToFit()
		button.tintColor = UIColor(white: 0.7, alpha: 0.5)
		self.handler = NCActionHandler(button, for: .touchUpInside) { [weak self] _ in
			guard let strongSelf = self as? TreeNode else {return}
			guard let controller = strongSelf.treeController else {return}
			controller.delegate?.treeController?(controller, accessoryButtonTappedWithNode: strongSelf)
		}
		
		cell.accessoryView = button
	}
}

fileprivate class NCZKillboardContactRow: NCContactRow, NCZKillboardFilterRow {
	
	var handler: NCActionHandler?
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCContactTableViewCell else {return}
		
		configureAccessoryButton(for: cell)
	}
}

fileprivate class NCZKillboardShipRow: TreeRow, NCZKillboardFilterRow {

	let ship: Any
	init(ship: Any, route: Route?) {
		self.ship = ship
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact, route: route)
	}
	
	var handler: NCActionHandler?

	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		if let group = ship as? NCDBInvGroup {
			cell.titleLabel?.text = group.groupName
			cell.iconView?.image = group.icon?.image?.image ?? NCDBEveIcon.defaultGroup.image?.image
		}
		else if let type = ship as? NCDBInvType {
			cell.titleLabel?.text = type.typeName
			cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		}
		
		configureAccessoryButton(for: cell)
	}
}

class NCZKillboardViewController: UITableViewController, TreeControllerDelegate, NCContactsSearchResultViewControllerDelegate {
	
	@IBOutlet var treeController: TreeController!
	
	private var defaultRows: [TreeNode]?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCContactTableViewCell.compact,
		                    Prototype.NCActionTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.noImage,
		                    Prototype.NCHeaderTableViewCell.default])
		
		
		treeController.delegate = self
		let rows = [
			NCActionRow(prototype: Prototype.NCActionTableViewCell.default, title: NSLocalizedString("Select Pilot", comment: "").uppercased(), route: Router.KillReports.SearchContact(delegate: self)),
			NCActionRow(prototype: Prototype.NCActionTableViewCell.default, title: NSLocalizedString("Select Ship", comment: "").uppercased(), route: Router.KillReports.TypePicker { [weak self] (controller, result) in
				self?.select(ship: result)
				controller.dismiss(animated: true, completion: nil)
			}),
			NCActionRow(prototype: Prototype.NCActionTableViewCell.default, title: NSLocalizedString("Select Solar System", comment: "").uppercased()),
			NCActionRow(prototype: Prototype.NCActionTableViewCell.default, title: NSLocalizedString("From Date", comment: "").uppercased()),
			NCActionRow(prototype: Prototype.NCActionTableViewCell.default, title: NSLocalizedString("To Date", comment: "").uppercased())
		]
		
		defaultRows = rows
		
		treeController.content = RootNode(rows)
	}
	
	private func select(ship: Any) {
		let row = NCZKillboardShipRow(ship: ship, route: (self.defaultRows?[1] as? TreeNodeRoutable)?.route)
		treeController.content?.children[1] = row
	}

	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.route?.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		if node is NCZKillboardContactRow {
			guard let row = defaultRows?[0] else {return}
			treeController.content?.children[0] = row
		}
	}
	
	//MARK: - NCContactsSearchResultViewControllerDelegate
	
	private lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
	
	func contactsSearchResultsViewController(_ controller: NCContactsSearchResultViewController, didSelect contact: NCContact) {
		controller.dismiss(animated: true, completion: nil)
		let row = NCZKillboardContactRow(contact: contact, dataManager: dataManager)
		row.route = Router.KillReports.SearchContact(delegate: self)
		treeController.content?.children[0] = row
	}
	
}
