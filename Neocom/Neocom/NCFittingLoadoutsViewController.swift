//
//  NCFittingLoadoutsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 10.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import CloudData
import EVEAPI

class NCLoadoutRow: TreeRow {
	let typeName: String
	let loadoutName: String
	let image: UIImage?
	let loadoutID: NSManagedObjectID
	let typeID: Int
	
	required init(loadout: NCLoadout, type: NCDBInvType) {
		typeName = type.typeName ?? ""
		loadoutName = loadout.name ?? ""
		image = type.icon?.image?.image
		loadoutID = loadout.objectID
		typeID = Int(loadout.typeID)
		super.init(prototype: Prototype.NCDefaultTableViewCell.default, route: Router.Fitting.Editor(loadoutID: loadout.objectID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = typeName
		cell.subtitleLabel?.text = loadoutName
		cell.iconView?.image = image
		cell.accessoryType = .disclosureIndicator
	}
	
	override var hashValue: Int {
		return loadoutID.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCLoadoutRow)?.hashValue == hashValue
	}
	
}

class NCLoadoutsSection<T: NCLoadoutRow>: TreeSection {
	let categoryID: NCDBDgmppItemCategoryID?
	let filter: NSPredicate?
	private var observer: NotificationObserver?
	
	init(categoryID: NCDBDgmppItemCategoryID?, filter: NSPredicate? = nil) {
		self.categoryID = categoryID
		self.filter = filter
		super.init()
		reload()
		
		observer = NotificationCenter.default.addNotificationObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: nil) { [weak self] note in
			if (note.object as? NSManagedObjectContext)?.persistentStoreCoordinator === NCStorage.sharedStorage?.persistentStoreCoordinator {
				self?.reload()
			}
		}
	}
	
	override var hashValue: Int {
		return categoryID?.hashValue ?? filter?.hash ?? super.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCLoadoutsSection)?.hashValue == hashValue
	}
	
	private func reload() {
		let categoryID = self.categoryID != nil ? Int32(self.categoryID!.rawValue) : nil
		
		NCStorage.sharedStorage?.performBackgroundTask { managedObjectContext in
			let request = NSFetchRequest<NCLoadout>(entityName: "Loadout")
			request.predicate = self.filter
			guard let loadouts = try? managedObjectContext.fetch(request) else {return}
			var groups = [String: DefaultTreeSection]()
			
			var sections = [TreeNode]()
			
			NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext in
				let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
				for loadout in loadouts {
					guard let type = invTypes[Int(loadout.typeID)] else {continue}
					if categoryID == nil || type.dgmppItem?.groups?.first(where: {($0 as? NCDBDgmppItemGroup)?.category?.category == categoryID!}) != nil {
						guard let name = type.group?.groupName else {continue}
						let key = name
						let section = groups[key]
						let row = T(loadout: loadout, type: type)
						if let section = section {
							section.children.append(row)
						}
						else {
							let section = DefaultTreeSection(nodeIdentifier: key, title: name.uppercased())
							section.children = [row]
							groups[key] = section
						}
					}
				}
			}
			
			for (_, group) in groups.sorted(by: { $0.key < $1.key}) {
				group.children = (group.children as? [NCLoadoutRow])?.sorted(by: { (a, b) -> Bool in
					return a.typeName == b.typeName ? a.loadoutName < b.loadoutName : a.typeName < b.typeName
				}) ?? []
				sections.append(group)
			}
			
			DispatchQueue.main.async {
				self.children = sections
			}
		}
	}
}

class NCFittingLoadoutsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default])
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		updateToolbar()
	}
	
	@IBAction func onDelete(_ sender: UIBarButtonItem) {
		guard let selected = treeController?.selectedNodes().flatMap ({($0 as? NCLoadoutRow)?.loadoutID}) else {return}
		guard !selected.isEmpty else {return}
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		controller.addAction(UIAlertAction(title: String(format: NSLocalizedString("Delete %d Loadouts", comment: ""), selected.count), style: .destructive) { [weak self] _ in
			NCStorage.sharedStorage?.performBackgroundTask { managedObjectContext in
				selected.forEach {
					guard let object = try? managedObjectContext.existingObject(with: $0) else {return}
					managedObjectContext.delete(object)
				}
			}
			self?.updateToolbar()
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		
		present(controller, animated: true, completion: nil)
		controller.popoverPresentationController?.barButtonItem = sender
	}
	
	@IBAction func onShare(_ sender: UIBarButtonItem) {
		guard let selected = treeController?.selectedNodes().flatMap ({($0 as? NCLoadoutRow)?.loadoutID}) else {return}
		
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		func loadouts(_ completionHandler: @escaping ([(typeID: Int, data: NCFittingLoadout, name: String)]) -> Void) {
			NCStorage.sharedStorage?.performBackgroundTask { managedObjectContext in
				let loadouts = selected.flatMap { loadoutID -> (typeID: Int, data: NCFittingLoadout, name: String)? in
					guard let loadout = (try? managedObjectContext.existingObject(with: loadoutID)) as? NCLoadout else {return nil}
					guard let data = loadout.data?.data else {return nil}
					
					return (typeID: Int(loadout.typeID), data: data, name: loadout.name ?? "")
				}
				DispatchQueue.main.async {
					completionHandler(loadouts)
				}
			}
		}
		
		weak var weakSelf = self
		
		
		func share(representation: NCLoadoutRepresentation) {
			guard let strongSelf = weakSelf else {return}
			let controller = UIActivityViewController(activityItems: [NCLoadoutActivityItem(representation: representation)], applicationActivities: nil)
			strongSelf.present(controller, animated: true, completion: nil)
			
		}
		
		if selected.count == 1 {
			controller.addAction(UIAlertAction(title: NSLocalizedString("EFT", comment: ""), style: .default, handler: { _ in
				loadouts { result in
					share(representation: .eft(result))
				}
			}))
		}
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("EVE XML", comment: ""), style: .default, handler: { _ in
			loadouts { result in
				share(representation: .xml(result))
			}
		}))
		
		if selected.count == 1 {
			controller.addAction(UIAlertAction(title: NSLocalizedString("Link", comment: ""), style: .default, handler: { _ in
				loadouts { result in
					share(representation: .httpURL(result))
				}
			}))
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Copy", comment: ""), style: .default, handler: { _ in
				loadouts { result in
					guard let value = (NCLoadoutRepresentation.eft(result).value as? [String])?.first else {return}
					UIPasteboard.general.string = value
				}
				
			}))
		}
		
		if let account = NCAccount.current {
			controller.addAction(UIAlertAction(title: NSLocalizedString("Save In-Game", comment: ""), style: .default, handler: { [weak self] _ in
				loadouts { result in
					guard let strongSelf = self else {return}
					guard var queue = NCLoadoutRepresentation.inGame(result).value as? [ESI.Fittings.MutableFitting] else {return}
					
					let dataManager = strongSelf.dataManager
					let progress = NCProgressHandler(viewController: strongSelf, totalUnitCount: Int64(queue.count))
					
					func dequeue() {
						if queue.isEmpty {
							progress.finish()
						}
						else {
							progress.progress.perform {
								dataManager.createFitting(fitting: queue.removeFirst()) { result in
									switch result {
									case let .failure(error):
										strongSelf.present(UIAlertController(error: error), animated: true, completion: nil)
										progress.finish()
									default:
										dequeue()
									}
								}
							}
						}
					}
					
					dequeue()
				}
			}))
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("EVE Mail", comment: ""), style: .default, handler: { [weak self] _ in
				loadouts { result in
					NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
						guard let urls = NCLoadoutRepresentation.dnaURL(result).value as? [URL] else {return}
						let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
						let font = UIFont.preferredFont(forTextStyle: .body)
						
						let body = NSMutableAttributedString()
						
						zip(urls, result).forEach {
							let name = !$0.1.name.isEmpty ? $0.1.name : invTypes[$0.1.typeID]?.typeName ?? NSLocalizedString("Unknown", comment: "")
							let s: NSAttributedString
							
							if body.length == 0 {
								s = name * [NSAttributedStringKey.link: $0.0, NSAttributedStringKey.font: font]
							}
							else {
								s = ", " * [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: UIColor.white] + name * [NSAttributedStringKey.link: $0.0, NSAttributedStringKey.font: font]
							}
							body.append(s)
						}
						
						body.append(" " * [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: UIColor.white])
						
						DispatchQueue.main.async {
							guard let strongSelf = self else {return}
							Router.Mail.NewMessage(recipients: nil, subject: nil, body: body).perform(source: strongSelf, sender: sender)
						}
					}
					
				}
			}))
		}
		
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		
		present(controller, animated: true, completion: nil)
		controller.popoverPresentationController?.barButtonItem = sender

	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		updateToolbar()
	}
	
	override func treeController(_ treeController: TreeController, didDeselectCellWithNode node: TreeNode) {
		super.treeController(treeController, didDeselectCellWithNode: node)
		updateToolbar()
	}
	
	func treeController(_ treeController: TreeController, didCollapseCellWithNode node: TreeNode) {
		updateToolbar()
	}
	
	func treeControllerDidUpdateContent(_ treeController: TreeController) {
		updateToolbar()
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCLoadoutRow else {return nil}
		
		let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { _,_  in
			guard let context = NCStorage.sharedStorage?.viewContext else {return}
			guard let loadout = (try? context.existingObject(with: node.loadoutID)) as? NCLoadout else {return}
			context.delete(loadout)
			if context.hasChanges {
				try? context.save()
			}
		}
		
		return [deleteAction]
	}
	
	
	private func updateToolbar() {
		let isEnabled = treeController?.selectedNodes().isEmpty == false
		toolbarItems?.last?.isEnabled = isEnabled
		toolbarItems?.first?.isEnabled = isEnabled
	}
}
