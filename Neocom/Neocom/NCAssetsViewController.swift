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
		                    Prototype.NCDefaultTableViewCell.default])
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
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.accessoryButtonRoute?.perform(source: self, view: treeController.cell(for: node))
		}
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
				var contents: [Int64: [ESI.Assets.Asset]] = [:]
				var typeIDs = Set<Int>()
				
				value.forEach {
					_ = (contents[$0.locationID]?.append($0)) ?? (contents[$0.locationID] = [$0])
					items[$0.itemID] = $0
					typeIDs.insert($0.typeID)
				}
				
				var types = [Int: NCDBInvType]()
				if typeIDs.count > 0 {
					let result: [NCDBInvType]? = managedObjectContext.fetch("InvType", where: "typeID in %@", typeIDs)
					result?.forEach {types[Int($0.typeID)] = $0}
				}
				
				func row(asset: ESI.Assets.Asset) -> DefaultTreeRow {
					let type = types[asset.typeID]
					let typeName = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
					let title: NSAttributedString
					if let qty = asset.quantity, qty > 1 {
						title = typeName + (" x" + NCUnitFormatter.localizedString(from: qty, unit: .none, style: .full)) * [NSForegroundColorAttributeName: UIColor.caption]
					}
					else {
						title = NSAttributedString(string: typeName)
					}
					var rows = contents[asset.itemID]?.map {row(asset: $0)} ?? []
					rows.sort { ($0.0.attributedTitle?.string ?? "") < ($0.1.attributedTitle?.string ?? "") }
					
					let subtitle = rows.count > 0 ? NCUnitFormatter.localizedString(from: rows.count, unit: .none, style: .full) + " " + NSLocalizedString("items", comment: "") : nil

					let route: Route?
					if let typeID = type?.typeID {
						route = Router.Database.TypeInfo(Int(typeID))
					}
					else {
						route = nil
					}
					
					let assetRow = DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.default,
					                  nodeIdentifier: "\(asset.itemID)",
					                  image: type?.icon?.image?.image,
					                  attributedTitle: title,
					                  subtitle: subtitle,
					                  accessoryType: rows.count > 0 ? .detailButton : .none,
					                  route: rows.count == 0 ? route : nil,
					                  accessoryButtonRoute: rows.count > 0 ? route : nil)
					assetRow.children = rows
					return assetRow
				}
				
				var sections = [DefaultTreeSection]()
				for locationID in Set(locations.keys).subtracting(Set(items.keys)) {
					guard var rows = contents[locationID]?.map ({row(asset: $0)}) else {continue}
					
					rows.sort { ($0.0.attributedTitle?.string ?? "") < ($0.1.attributedTitle?.string ?? "") }
					
					let location = locations[locationID]
					let title = location?.displayName ?? NSAttributedString(string: NSLocalizedString("Unknown Location", comment: ""))
					let nodeIdentifier = location?.solarSystemName ?? "~"
						
					sections.append(DefaultTreeSection(nodeIdentifier: nodeIdentifier, attributedTitle: title, children: rows))
				}
				sections.sort {$0.nodeIdentifier! < $1.nodeIdentifier!}
				
				DispatchQueue.main.async {
					if self.treeController.content == nil {
						let root = TreeNode()
						root.children = sections
						self.treeController.content = root
					}
					else {
						self.treeController.content?.children = sections
					}
				}
			}
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: assets?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
}
