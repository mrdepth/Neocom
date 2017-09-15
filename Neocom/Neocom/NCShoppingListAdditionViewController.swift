//
//  NCShoppingListAdditionViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCShoppingItemRow: NCFetchedResultsObjectNode<NCShoppingItem>, TreeNodeRoutable {
	var route: Route?
	var accessoryButtonRoute: Route?
	
	required init(object: NCShoppingItem) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.default.reuseIdentifier
		
		var slots = [NCItemFlag: [NCShoppingItemRow]]()

		object.contents?.forEach {
			guard let item = $0 as? NCShoppingItem else {return}
			let flag = NCItemFlag(rawValue: item.flag) ?? .cargo
			let row = NCShoppingItemRow(object: item)
			_ = (slots[flag]?.append(row)) ?? (slots[flag] = [row])
		}
		
		children = slots.sorted {$0.key.rawValue < $1.key.rawValue}.map {
			let section = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.image, nodeIdentifier: "\(object.objectID.uriRepresentation().absoluteString).\($0.key.rawValue)", image: $0.key.image, title: $0.key.title?.uppercased(), children: $0.value)
			section.isExpandable = false
			return section
		}
		accessoryButtonRoute = Router.Database.TypeInfo(Int(object.typeID))
	}
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[Int(self.object.typeID)]
	}()
	
	var price: Double?
	
	var contents: [Int: Int] {
		var contents = [Int: Int]()
		children.forEach {
			guard let item = $0 as? NCShoppingItemRow else {return}
			contents[Int(item.object.typeID)] = (contents[Int(item.object.typeID)] ?? 0) + Int(item.object.quantity)
			item.contents.forEach {
				contents[$0.key] = (contents[$0.key] ?? 0) + $0.value
			}
		}
		return contents
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.object = object
		cell.accessoryType = .detailButton
		
		let quantity = object.totalQuantity
		
		let typeName = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		let s = NCUnitFormatter.localizedString(from: quantity, unit: .none, style: .full)
		if let name = object.name, !name.isEmpty {
			cell.titleLabel?.attributedText = "\(typeName) / \(name) " + "x\(s)" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
		}
		else {
			cell.titleLabel?.attributedText = "\(typeName) " + "x\(s)" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
		}
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		
		if let price = price {
			let cost = price * Double(quantity)
			cell.subtitleLabel?.text = NSLocalizedString("Cost: ", comment: "") + (cost > 0 ? NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .full) : NSLocalizedString("n/a", comment: ""))
		}
		if price == nil {
			let typeID = Int(object.typeID)
			NCDataManager().prices(typeIDs: Set([typeID])) { result in
				self.price = result[typeID] ?? 0
				if (cell.object as? NCShoppingItem) == self.object {
					let cost = self.price! * Double(quantity)
					cell.subtitleLabel?.text = NSLocalizedString("Cost: ", comment: "") + (cost > 0 ? NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .full) : NSLocalizedString("n/a", comment: ""))
				}
			}
		}
		else {
		}
	}
}

class NCShoppingListAdditionViewController: UITableViewController, TreeControllerDelegate {
	
	@IBOutlet var treeController: TreeController!
	
	var items: [NCShoppingItem]?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.image])
		
		treeController.delegate = self
		
		let rows = items?.map {NCShoppingItemRow(object: $0)} ?? []
		treeController.content = RootNode(rows)
		navigationController?.isToolbarHidden = false
		navigationController?.toolbar.barStyle = .black
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setToolbarHidden(false, animated: animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.setToolbarHidden(true, animated: animated)
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.route?.perform(source: self, sender: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
}
