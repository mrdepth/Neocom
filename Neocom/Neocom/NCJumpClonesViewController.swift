//
//  NCJumpClonesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCJumpClonesViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		registerRefreshable()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.attribute,
		                    Prototype.NCDefaultTableViewCell.placeholder])
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		reload()
	}

	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.route?.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}

	
	//MARK: - NCRefreshable
	
	private var observer: NCManagedObjectObserver?
	private var clones: NCCachedResult<EVE.Char.Clones>?
	private var locations: [Int64: NCLocation]?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		title = account.characterName
		
		let progress = Progress(totalUnitCount: 1)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		
		progress.perform {
			dataManager.clones { result in
				self.clones = result
				
				switch result {
				case let .success(value, record):
					if let record = record {
						self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
							if let value = result.value, let locations = value.jumpClones?.map ({$0.locationID}), !locations.isEmpty {
								dataManager.locations(ids: Set(locations)) { result in
									self?.locations = result
									self?.reloadSections()
								}
							}
						}
					}
					
					if let locations = value.jumpClones?.map ({$0.locationID}), !locations.isEmpty {
						dataManager.locations(ids: Set(locations)) { result in
							self.locations = result
							self.reloadSections()
							completionHandler?()
						}
					}
					else {
						completionHandler?()
					}

				case .failure:
					completionHandler?()
				}
				
				
			}
		}
	}
	
	private func reloadSections() {
		if let value = clones?.value {
			tableView.backgroundView = nil
			
			let t = 3600 * 24 + (value.cloneJumpDate ?? .distantPast).timeIntervalSinceNow
			let s = String(format: NSLocalizedString("Clone jump availability: %@", comment: ""), t > 0 ? NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes) : NSLocalizedString("Now", comment: ""))
			
			var sections = [TreeNode]()
			
			sections.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
			               nodeIdentifier: "Jump",
			               title: NSLocalizedString("Next Clone Jump Availability", comment: "").uppercased(),
			               subtitle: s))

			let invTypes = NCDatabase.sharedDatabase?.invTypes
			for clone in value.jumpClones ?? [] {
				
				var rows = [TreeRow]()

				let jumpCloneImplants = value.jumpCloneImplants?.filter {$0.jumpCloneID == clone.jumpCloneID}
				let implants = jumpCloneImplants?.flatMap {invTypes?[$0.typeID]} ?? []
				
				let list = [(NCDBAttributeID.intelligenceBonus, NSLocalizedString("Intelligence", comment: "")),
				            (NCDBAttributeID.memoryBonus, NSLocalizedString("Memory", comment: "")),
				            (NCDBAttributeID.perceptionBonus, NSLocalizedString("Perception", comment: "")),
				            (NCDBAttributeID.willpowerBonus, NSLocalizedString("Willpower", comment: "")),
				            (NCDBAttributeID.charismaBonus, NSLocalizedString("Charisma", comment: ""))]
				
				for (attribute, name) in list {
					if let implant = implants.first(where: {($0.allAttributes[attribute.rawValue]?.value ?? 0) > 0}) {
						rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                           nodeIdentifier: name,
						                           image: implant.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image,
						                           title: implant.typeName?.uppercased(),
						                           subtitle: "\(name) +\(Int(implant.allAttributes[attribute.rawValue]!.value))",
							accessoryType: .disclosureIndicator,
							route: Router.Database.TypeInfo(implant)
						))
					}
				}
				
				if rows.isEmpty {
					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, nodeIdentifier: "NoImplants", title: NSLocalizedString("No Implants Installed", comment: "").uppercased()))
				}
				sections.append(DefaultTreeSection(nodeIdentifier: "\(clone.jumpCloneID)", attributedTitle: locations?[clone.locationID]?.displayName.uppercased(), children: rows))
			}
			
			if treeController.content == nil {
				let root = TreeNode()
				root.children = sections
				treeController.content = root
			}
			else {
				treeController.content?.children = sections
			}

		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: clones?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
}
