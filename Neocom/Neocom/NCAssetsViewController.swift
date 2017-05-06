//
//  NCAssetsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCAssetsViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
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
	private var assets: NCCachedResult<[ESI.Assets.Asset]>?
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
			dataManager.assets { result in
				self.assets = result
				
				switch result {
				case let .success(_, record):
					if let record = record {
						self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
							self?.reloadLocations(dataManager: dataManager) {
								self?.reloadSections()
								completionHandler?()
							}
						}
					}
					
					self.reloadLocations(dataManager: dataManager) {
						self.reloadSections()
						completionHandler?()
					}
				case .failure:
					completionHandler?()
				}
				
				
			}
		}
	}
	
	private func reloadLocations(dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		guard let value = assets?.value else {
			completionHandler?()
			return
		}
		var locationIDs = Set(value.map {$0.locationID})
		let itemIDs = Set(value.map {$0.itemID})
		locationIDs.subtract(itemIDs)
		
		guard !locationIDs.isEmpty else {
			completionHandler?()
			return
		}
		
		dataManager.locations(ids: locationIDs) { [weak self] result in
			self?.locations = result
			completionHandler?()
		}
		
	}
	
	private func reloadSections() {
		if let value = assets?.value {
			tableView.backgroundView = nil
			let locations = self.locations ?? [:]
			
			NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
				var items: [Int64: ESI.Assets.Asset] = [:]
				var contents: [Int64: [ESI.Assets.Asset]]
				
				value.forEach {
					_ = (contents[$0.locationID]?.append($0)) ?? (contents[$0.locationID] = [$0])
					items[$0.itemID] = $0
				}
				
				func row(asset: ESI.Assets.Asset) -> NCAssetRow {
					return NCAssetRow(asset: asset, children: contents[asset.itemID]?.map {row(asset: $0)})
				}
				
				var sections = [DefaultTreeSection]()
				for locationID in Set(locations.keys).subtracting(Set(items.keys)) {
					let rows = contents[locationID]?.map {row(asset: $0)}
					let location = locations[locationID]
					let title = location?.displayName ?? NSAttributedString(string: NSLocalizedString("Unknown Location", comment: ""))
					let nodeIdentifier = location?.solarSystemName ?? "~"
						
					sections.append(DefaultTreeSection(nodeIdentifier: nodeIdentifier, attributedTitle: title, children: rows))
				}
				sections.sort {$0.nodeIdentifier! < $1.nodeIdentifier!}
				
			}
			
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
			tableView.backgroundView = NCTableViewBackgroundLabel(text: assets?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
}
