//
//  NCAssetsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCAssetRow: DefaultTreeRow {
	
	init(asset: ESI.Assets.Asset, contents: [Int64: [ESI.Assets.Asset]], types: [Int: NCDBInvType]) {
		let type = types[asset.typeID]
		let typeName = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		let title: NSAttributedString
		if let qty = asset.quantity, qty > 1 {
			title = typeName + (" x" + NCUnitFormatter.localizedString(from: qty, unit: .none, style: .full)) * [NSForegroundColorAttributeName: UIColor.caption]
		}
		else {
			title = NSAttributedString(string: typeName)
		}
		
		var children: [TreeNode] = []
		
		let subtitle: String?
		
		if let nested = contents[asset.itemID], !contents.isEmpty {
			var map: [NCItemFlag:[DefaultTreeRow]] = [:]
			var rows = [DefaultTreeRow]()
			
			nested.forEach {
				let assetRow = NCAssetRow(asset: $0, contents: contents, types: types)
				if let flag = NCItemFlag(flag: $0.locationFlag) {
					_ = (map[flag]?.append(assetRow)) ?? (map[flag] = [assetRow])
				}
				else {
					rows.append(assetRow)
				}
			}
			
			rows.sort { ($0.0.attributedTitle?.string ?? "") < ($0.1.attributedTitle?.string ?? "") }
			children = rows
			
			let sections = map.sorted {$0.key.rawValue < $1.key.rawValue}.map { i -> DefaultTreeSection in
				let section = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.image,
				                                 nodeIdentifier: "\(asset.itemID).\(i.key.rawValue)",
					image: i.key.image,
					title: i.key.title?.uppercased(),
					children: i.value.sorted { ($0.0.attributedTitle?.string ?? "") < ($0.1.attributedTitle?.string ?? "") })
				section.isExpandable = false
				return section
			}
			
			children.append(contentsOf: sections as [TreeNode])
			subtitle = !nested.isEmpty ? NCUnitFormatter.localizedString(from: nested.count, unit: .none, style: .full) + " " + NSLocalizedString("items", comment: "") : nil
		}
		else {
			subtitle = nil
		}
		
		
		
		let route: Route?
		if let typeID = type?.typeID {
			route = Router.Database.TypeInfo(Int(typeID))
		}
		else {
			route = nil
		}
		let hasLoadout = type?.group?.category?.categoryID == Int32(NCDBCategoryID.ship.rawValue) && !children.isEmpty
		
		
		super.init(prototype: Prototype.NCDefaultTableViewCell.default,
		           nodeIdentifier: "\(asset.itemID)",
			image: type?.icon?.image?.image,
			attributedTitle: title,
			subtitle: subtitle,
			accessoryType: hasLoadout ? .detailButton : .disclosureIndicator,
			route: route,
			accessoryButtonRoute: hasLoadout ? Router.Fitting.Editor(asset: asset, contents: contents) : nil,
			object: asset)
		self.children = children
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		cell.indentationWidth = 16
	}
}

class NCAssetsViewController: NCTreeViewController, NCSearchableViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.image,
		                    Prototype.NCDefaultTableViewCell.default])
		
		setupSearchController(searchResultsController: storyboard!.instantiateViewController(withIdentifier: "NCAssetsSearchResultViewController") as! NCAssetsSearchResultViewController)
		
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		dataManager.assets { result in
			self.assets = result
			completionHandler([result.cacheRecord].flatMap {$0})
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = assets?.value {
			tableView.backgroundView = nil
			
			var locationIDs = Set(value.map {$0.locationID})
			let itemIDs = Set(value.map {$0.itemID})
			locationIDs.subtract(itemIDs)
			
			dataManager.locations(ids: locationIDs) { locations in
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
					
					var sections = [DefaultTreeSection]()
					for locationID in Set(locations.keys).subtracting(Set(items.keys)) {
						guard var rows = contents[locationID]?.map ({NCAssetRow(asset: $0, contents: contents, types: types)}) else {continue}
						
						rows.sort { ($0.0.attributedTitle?.string ?? "") < ($0.1.attributedTitle?.string ?? "") }
						
						let location = locations[locationID]
						let title = location?.displayName ?? NSAttributedString(string: NSLocalizedString("Unknown Location", comment: ""))
						let nodeIdentifier = "\(location?.solarSystemName ?? "")\(locationID)"
						
						let section = DefaultTreeSection(nodeIdentifier: nodeIdentifier, attributedTitle: title.uppercased(), children: rows)
						section.isExpanded = false
						sections.append(section)
					}
					sections.sort {$0.nodeIdentifier! < $1.nodeIdentifier!}
					
					DispatchQueue.main.async {
						
						if self.treeController?.content == nil {
							self.treeController?.content = RootNode(sections)
						}
						else {
							self.treeController?.content?.children = sections
						}
						
						
						self.contents = contents
						if let searchController = self.searchController, let searchResultsController = searchController.searchResultsController as? NCAssetsSearchResultViewController {
							searchResultsController.items = items
							searchResultsController.contents = contents
							searchResultsController.locations = locations
							searchResultsController.typeIDs = typeIDs
							if searchController.isActive {
								searchResultsController.updateSearchResults(for: searchController)
							}
						}

						self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
						completionHandler()
					}
				}
			}
		}
		else {
			tableView.backgroundView =  treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: assets?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private var assets: NCCachedResult<[ESI.Assets.Asset]>?
	var contents: [Int64: [ESI.Assets.Asset]]?
	
	//MARK: - NCSearchableViewController
	var searchController: UISearchController?
	
	func updateSearchResults(for searchController: UISearchController) {
		(searchController.searchResultsController as? NCAssetsSearchResultViewController)?.updateSearchResults(for: searchController)
	}
	

}
