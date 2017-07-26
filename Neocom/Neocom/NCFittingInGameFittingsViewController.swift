//
//  NCFittingInGameFittingsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

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

class NCFittingInGameFittingsViewController: NCTreeViewController, NCRefreshable {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default])

		registerRefreshable()
		
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if treeController?.content == nil {
			self.treeController?.content = TreeNode()
			reload()
		}
	}
	
	//MARK: - TreeControllerDelegate

	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCInGameFittingRow else {return nil}
		
		let fitting = node.fitting
		
		return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { [weak self] _ in
			guard let strongSelf = self else {return}
			guard let account = NCAccount.current else {return}
			strongSelf.tableView.isUserInteractionEnabled = false
			guard let cell = strongSelf.treeController?.cell(for: node) else {return}

			let dataManager = NCDataManager(account: account)
			
			let progress = NCProgressHandler(view: cell, totalUnitCount: 1, activityIndicatorStyle: .white)
			progress.progress.perform {
				dataManager.deleteFitting(fittingID: fitting.fittingID) { result in
					
					strongSelf.tableView.isUserInteractionEnabled = true
					
					switch result {
					case .success:
						guard let record = strongSelf.fittings?.cacheRecord else {return}
						guard var fittings = record.data?.data as? [ESI.Fittings.Fitting] else {return}
						guard let i = fittings.index(where: {$0.fittingID == fitting.fittingID}) else {return}
						fittings.remove(at: i)
						
						
						record.data?.data = fittings as NSArray
						if record.managedObjectContext?.hasChanges == true {
							try? record.managedObjectContext?.save()
						}
						if let parent = node.parent, let i = parent.children.index(of: node) {
							parent.children.remove(at: i)
							if parent.children.isEmpty, let root = parent.parent, let i = root.children.index(of: parent) {
								root.children.remove(at: i)
							}
						}
					case let .failure(error):
						strongSelf.present(UIAlertController(error: error), animated: true, completion: nil)
					}
					progress.finish()
				}
			}
		})]
	}
	
	//MARK: - NCRefreshable
	
	private var observer: NCManagedObjectObserver?
	private var fittings: NCCachedResult<[ESI.Fittings.Fitting]>?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		
		let progress = Progress(totalUnitCount: 2)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		
		progress.perform {

			dataManager.fittings { result in
				self.fittings = result
				
				switch result {
				case let .success(_, record):
					if let record = record {
						self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
							self?.reloadSections()
						}
					}
				case .failure:
					break
				}
				progress.perform {
					self.reloadSections()
					completionHandler?()
				}
			}
		}
	}
	
	private func reloadSections() {
		if let value = fittings?.value {
			tableView.backgroundView = nil
			
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

				DispatchQueue.main.async {
					
					if self.treeController?.content == nil {
						self.treeController?.content = RootNode(sections)
					}
					else {
						self.treeController?.content?.children = sections
					}
					self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
				}
			}
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: fittings?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
	
}
