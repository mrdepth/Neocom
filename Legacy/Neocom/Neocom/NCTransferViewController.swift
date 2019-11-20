//
//  NCTransferViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 17.10.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import EVEAPI

class NCTransferRow: TreeRow {
	let loadout: (typeID: Int, data: NCFittingLoadout, name: String)
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.loadout.typeID]
	}()
	
	init(loadout: (typeID: Int, data: NCFittingLoadout, name: String)) {
		self.loadout = loadout
		super.init(prototype: Prototype.NCDefaultTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.subtitleLabel?.text = loadout.name
	}
}

class NCTransferViewController: NCTreeViewController {
	@IBOutlet weak var selectAllItem: UIBarButtonItem!
	var loadouts: NCLoadoutRepresentation?
	private var allRows: [TreeNode]?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.setToolbarHidden(false, animated: false)
		setEditing(true, animated: false)
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default])
		
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		let fileManager = FileManager.default
		guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.shimanski.neocom") else {return}
		let flagURL = groupURL.appendingPathComponent(".already_transferred")
		try? "".write(to: flagURL, atomically: true, encoding: .utf8)
		
		let loadoutsURL = groupURL.appendingPathComponent("loadouts.xml")
		try? fileManager.removeItem(at: loadoutsURL)
	}
	
	override func content() -> Future<TreeNode?> {
		if let loadouts = loadouts?.loadouts {
			return NCDatabase.sharedDatabase!.performBackgroundTask { managedObjectContext -> TreeNode? in
				let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
				var groups = [String: [NCTransferRow]]()
				
				for loadout in loadouts {
					guard let type = invTypes[loadout.typeID] else {continue}
					guard let group = type.group?.groupName?.uppercased() else {continue}
					groups[group, default: []].append(NCTransferRow(loadout: loadout))
				}
				
				let sections = groups.sorted {$0.key < $1.key}.map {
					DefaultTreeSection(title: $0.key, children: $0.value)
				}
				guard !sections.isEmpty else {throw NCTreeViewControllerError.noResult}
				return RootNode(sections)
			}.finally(on: .main) {
				guard let sections = self.treeController?.content?.children else {return}
				let allRows = sections.map{$0.children}.joined()
				allRows.forEach {
					self.treeController?.selectCell(for: $0, animated: false, scrollPosition: .none)
				}
				self.allRows = Array(allRows)
				self.updateButtons()
			}
		}
		else {
			return .init(.failure(NCTreeViewControllerError.noResult))
		}
		
	}
	
	@IBAction func onCancel(_ sender: Any) {
		let controller = UIAlertController(title: NSLocalizedString("Cancel Import", comment: ""), message: NSLocalizedString("Are you sure you want to cancel? You can finish import later.", comment: ""), preferredStyle: .alert)
		controller.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: { [weak self] (_) in
			self?.dismiss(animated: true, completion: nil)
		}))

		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))

		present(controller, animated: true, completion: nil)
	}
	
	
	@IBAction func onDone(_ sender: Any) {
		dismiss(animated: true, completion: nil)
		guard let loadouts = loadouts?.loadouts, !loadouts.isEmpty else {return}
		let progress = NCProgressHandler(viewController: self, totalUnitCount: Int64(loadouts.count))
		
		UIApplication.shared.beginIgnoringInteractionEvents()
		NCStorage.sharedStorage?.performBackgroundTask { managedObjectContext in
			loadouts.forEach { i in
				let loadout = NCLoadout(entity: NSEntityDescription.entity(forEntityName: "Loadout", in: managedObjectContext)!, insertInto: managedObjectContext)
				loadout.data = NCLoadoutData(entity: NSEntityDescription.entity(forEntityName: "LoadoutData", in: managedObjectContext)!, insertInto: managedObjectContext)
				loadout.typeID = Int32(i.typeID)
				loadout.name = i.name
				loadout.data?.data = i.data
				loadout.uuid = UUID().uuidString
				progress.progress.completedUnitCount += 1
			}
			DispatchQueue.main.async {
				progress.finish()
				UIApplication.shared.endIgnoringInteractionEvents()
				self.dismiss(animated: true, completion: nil)
			}
		}

	}
	
	@IBAction func onSelectAll(_ sender: Any) {
		if treeController?.selectedNodes().count == allRows?.count {
			treeController?.selectedNodes().forEach {
				treeController?.deselectCell(for: $0, animated: true)
			}
		}
		else {
			allRows?.forEach {
				treeController?.selectCell(for: $0, animated: true, scrollPosition: .none)
			}
		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		return node is NCTransferRow ? [] : nil
	}
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		updateButtons()
	}
	
	override func treeController(_ treeController: TreeController, didDeselectCellWithNode node: TreeNode) {
		super.treeController(treeController, didDeselectCellWithNode: node)
		updateButtons()
	}
	
	private func updateButtons() {
		if allRows?.isEmpty == false {
			selectAllItem.isEnabled = true
			if treeController?.selectedNodes().count == allRows?.count {
				selectAllItem.title = NSLocalizedString("Deselect All", comment: "")
			}
			else {
				selectAllItem.title = NSLocalizedString("Select All", comment: "")
			}
		}
	}

}
