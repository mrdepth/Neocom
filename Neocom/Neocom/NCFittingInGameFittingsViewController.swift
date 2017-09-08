//
//  NCFittingInGameFittingsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import Alamofire

class NCInGameFittingRow: TreeRow {
	
	let typeName: String
	let loadoutName: String
	let image: UIImage?
	let fitting: ESI.Fittings.Fitting
	
	required init(fitting: ESI.Fittings.Fitting, type: NCDBInvType) {
		typeName = type.typeName ?? ""
		loadoutName = fitting.name
		image = type.icon?.image?.image
		self.fitting = fitting
		super.init(prototype: Prototype.NCDefaultTableViewCell.default, route: Router.Fitting.Editor(fitting: fitting))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = typeName
		cell.subtitleLabel?.text = loadoutName
		cell.iconView?.image = image
		cell.accessoryType = .disclosureIndicator
	}
	
	override var hashValue: Int {
		return fitting.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCInGameFittingRow)?.hashValue == hashValue
	}
}

class NCFittingInGameFittingsViewController: NCTreeViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default])

		
	}

	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		updateToolbar()
	}
	
	private var isDeleting: Bool = false
	
	@IBAction func onDelete(_ sender: UIBarButtonItem) {
		guard !isDeleting else {return}
		guard var selected = treeController?.selectedNodes().flatMap ({$0 as? NCInGameFittingRow}) else {return}
		guard !selected.isEmpty else {return}
		
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		controller.addAction(UIAlertAction(title: String(format: NSLocalizedString("Delete %d Loadouts", comment: ""), selected.count), style: .destructive) { [weak self] _ in
			guard let strongSelf = self else {return}
			strongSelf.isDeleting = true
			
			let progress = NCProgressHandler(viewController: strongSelf, totalUnitCount: Int64(selected.count))
			strongSelf.tableView.isUserInteractionEnabled = false
			
			func dequeue() {
				if selected.isEmpty {
					strongSelf.tableView.isUserInteractionEnabled = true
					if let context = strongSelf.fittings?.cacheRecord?.managedObjectContext, context.hasChanges {
						try? context.save()
					}
					strongSelf.updateToolbar()
					strongSelf.isDeleting = false
					progress.finish()
				}
				else {
					progress.progress.perform {
						strongSelf.deleteFitting(from: selected.removeFirst()) { _ in
							dequeue()
						}
					}
				}
			}
			dequeue()

		})
		
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
		tableView.backgroundView = treeController.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: fittings?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
	}
	
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCInGameFittingRow else {return nil}
		
		return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { [weak self, weak node] _ in
			guard let strongSelf = self else {return}
			guard let node = node else {return}
			guard let cell = strongSelf.treeController?.cell(for: node) else {return}

			strongSelf.tableView.isUserInteractionEnabled = false

			let progress = NCProgressHandler(view: cell, totalUnitCount: 1, activityIndicatorStyle: .white)
			progress.progress.perform {
				strongSelf.deleteFitting(from: node) { result in

					strongSelf.tableView.isUserInteractionEnabled = true
					
					switch result {
					case .success:
						if let context = strongSelf.fittings?.cacheRecord?.managedObjectContext, context.hasChanges {
							try? context.save()
						}
					case let .failure(error):
						strongSelf.present(UIAlertController(error: error), animated: true, completion: nil)
					}
					progress.finish()
				}
			}
		})]
	}
	
	private var fittings: NCCachedResult<[ESI.Fittings.Fitting]>?
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {

		Progress(totalUnitCount: 1).perform {

			dataManager.fittings { result in
				self.fittings = result
				completionHandler([result.cacheRecord].flatMap {$0})
			}
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = fittings?.value {
			tableView.backgroundView = nil
			
			let progress = Progress(totalUnitCount: 1)
			
			NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
				var groups = [String: DefaultTreeSection]()
				
				let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
				for fitting in value {
					guard let type = invTypes[Int(fitting.shipTypeID)] else {continue}
					guard let name = type.group?.groupName else {continue}
					let key = name
					let section = groups[key]
					let row = NCInGameFittingRow(fitting: fitting, type: type)
					if let section = section {
						section.children.append(row)
					}
					else {
						let section = DefaultTreeSection(nodeIdentifier: key, title: name.uppercased())
						section.children = [row]
						groups[key] = section
					}
				}
				
				var sections = [TreeNode]()
				for (_, group) in groups.sorted(by: { $0.key < $1.key}) {
					group.children = (group.children as? [NCInGameFittingRow])?.sorted(by: { (a, b) -> Bool in
						return a.typeName == b.typeName ? a.loadoutName < b.loadoutName : a.typeName < b.typeName
					}) ?? []
					sections.append(group)
				}
				
				progress.completedUnitCount += 1
				
				DispatchQueue.main.async {
					
					if self.treeController?.content == nil {
						self.treeController?.content = RootNode(sections)
					}
					else {
						self.treeController?.content?.children = sections
					}
					self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
					completionHandler()
				}
			}
			
		}
		else {
			tableView.backgroundView = treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: fittings?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private func deleteFitting(from node: NCInGameFittingRow, completionHandler: @escaping (Result<String>) -> Void) {
		Progress(totalUnitCount: 1).perform {
			dataManager.deleteFitting(fittingID: node.fitting.fittingID) { result in
				switch result {
				case .success:
					guard let record = self.fittings?.cacheRecord else {return}
					guard var fittings = record.data?.data as? [ESI.Fittings.Fitting] else {return}
					guard let i = fittings.index(where: {$0.fittingID == node.fitting.fittingID}) else {return}
					fittings.remove(at: i)
					
					
					record.data?.data = fittings as NSArray
					
					if let parent = node.parent, let i = parent.children.index(of: node) {
						parent.children.remove(at: i)
						if parent.children.isEmpty, let root = parent.parent, let i = root.children.index(of: parent) {
							root.children.remove(at: i)
						}
					}
				case .failure:
					break
				}
				completionHandler(result)

			}
		}
	}
	
	private func updateToolbar() {
		toolbarItems?.last?.isEnabled = treeController?.selectedNodes().isEmpty == false
	}

}
