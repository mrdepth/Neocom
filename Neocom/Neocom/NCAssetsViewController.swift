//
//  NCAssetsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

protocol NCAsset {
	var itemID: Int64 {get}
	var flag: NCItemFlag? {get}
	var locationID: Int64 {get}
//	public var locationType: Assets.Asset.GetCharactersCharacterIDAssetsLocationType
	var quantity: Int {get}
	var typeID: Int {get}
}

extension ESI.Assets.Asset: NCAsset {
	var flag: NCItemFlag? {
		return NCItemFlag(flag: self.locationFlag)
	}
}

extension ESI.Assets.CorpAsset: NCAsset {
	var flag: NCItemFlag? {
		return NCItemFlag(flag: self.locationFlag)
	}
}

class NCAssetRow: DefaultTreeRow {
	
	init(asset: NCAsset, contents: [Int64: [NCAsset]], types: [Int: NCDBInvType]) {
		let type = types[asset.typeID]
		let typeName = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		let title: NSAttributedString
		if asset.quantity > 1 {
			title = typeName + (" x" + NCUnitFormatter.localizedString(from: asset.quantity, unit: .none, style: .full)) * [NSAttributedStringKey.foregroundColor: UIColor.caption]
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
				if let flag = $0.flag {
					_ = (map[flag]?.append(assetRow)) ?? (map[flag] = [assetRow])
				}
				else {
					rows.append(assetRow)
				}
			}
			
			rows.sort { ($0.attributedTitle?.string ?? "") < ($1.attributedTitle?.string ?? "") }
			children = rows
			
			let sections = map.sorted {$0.key.rawValue < $1.key.rawValue}.map { i -> DefaultTreeSection in
				let section = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.image,
				                                 nodeIdentifier: "\(asset.itemID).\(i.key.rawValue)",
					image: i.key.image,
					title: i.key.title?.uppercased(),
					children: i.value.sorted { ($0.attributedTitle?.string ?? "") < ($1.attributedTitle?.string ?? "") })
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
			route: hasLoadout ? Router.Fitting.Editor(asset: asset, contents: contents) : route,
			accessoryButtonRoute: hasLoadout ? route : nil,
			object: asset)
		self.children = children
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		cell.indentationWidth = 16
	}
}

class NCAssetsViewController: NCTreeViewController, NCSearchableViewController {
	
	var owner = Owner.character
	
	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.image,
		                    Prototype.NCDefaultTableViewCell.default])
		
		setupSearchController(searchResultsController: storyboard!.instantiateViewController(withIdentifier: "NCAssetsSearchResultViewController") as! NCAssetsSearchResultViewController)
		
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		let progress = Progress(totalUnitCount: 3)
		
		switch owner {
		case .character:
				OperationQueue(qos: .utility).async { () -> [CachedValue<[ESI.Assets.Asset]>] in
					var assets = [CachedValue<[ESI.Assets.Asset]>]()
					
					for i in 1...10 {
						let page = try progress.perform{self.dataManager.assets(page: i)}.get()
						guard page.value?.isEmpty == false else {break}
						assets.append(page)
					}
					return Array(assets)
				}.then(on: .main) { assets in
						self.assets = assets
						completionHandler(assets.flatMap {$0.cacheRecord})
				}.catch(on: .main) { error in
						completionHandler([])
						self.tableView.backgroundView =  NCTableViewBackgroundLabel(text: error.localizedDescription)
				}
		case .corporation:
			OperationQueue(qos: .utility).async { () -> [CachedValue<[ESI.Assets.CorpAsset]>] in
				var assets = [CachedValue<[ESI.Assets.CorpAsset]>]()
				
				for i in 1...10 {
					let page = try progress.perform{self.dataManager.corpAssets(page: i)}.get()
					guard page.value?.isEmpty == false else {break}
					assets.append(page)
				}
				return assets
			}.then(on: .main) { assets in
					self.corpAssets = assets
					completionHandler(assets.flatMap {$0.cacheRecord})
			}.catch(on: .main) { error in
					completionHandler([])
					self.error = error
//					self.tableView.backgroundView =  NCTableViewBackgroundLabel(text: error.localizedDescription)
			}
		}
		
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		var sections = [DefaultTreeSection]()
		var contents: [Int64: [NCAsset]] = [:]
		var items: [Int64: NCAsset] = [:]
		var typeIDs = Set<Int>()
		var locations: [Int64: NCLocation] = [:]
		
		let assets = self.assets
		let corpAssets = self.corpAssets
		OperationQueue(qos: .utility).async { () -> [NCAsset]? in
			switch self.owner {
			case .character:
				return assets?.flatMap({ $0.value }).joined().filter({$0.locationFlag != .skill && $0.locationFlag != .implant}) as [NCAsset]?
			case .corporation:
				return corpAssets?.flatMap({ $0.value }).joined().filter({$0.locationFlag != .skill && $0.locationFlag != .implant}) as [NCAsset]?
			}
		}.then { assets in
			if let value = assets {
				var locationIDs = Set(value.map {$0.locationID})
				let itemIDs = Set(value.map {$0.itemID})
				locationIDs.subtract(itemIDs)
				
				try? locations = self.dataManager.locations(ids: locationIDs).get()
				NCDatabase.sharedDatabase!.performTaskAndWait { (managedObjectContext) in
					
					value.forEach {
						contents[$0.locationID, default: []].append($0)
						items[$0.itemID] = $0
						typeIDs.insert($0.typeID)
					}
					
					var types = [Int: NCDBInvType]()
					if typeIDs.count > 0 {
						let result: [NCDBInvType]? = managedObjectContext.fetch("InvType", where: "typeID in %@", typeIDs)
						result?.forEach {types[Int($0.typeID)] = $0}
					}
					
					var unknown = [NCAssetRow]()
					for locationID in locationIDs {
						guard var rows = contents[locationID]?.map ({NCAssetRow(asset: $0, contents: contents, types: types)}) else {continue}
						
						
						if let location = locations[locationID] {
							rows.sort { ($0.attributedTitle?.string ?? "") < ($1.attributedTitle?.string ?? "") }
							let title = location.displayName
							let nodeIdentifier = "\(location.solarSystemName ?? "")\(locationID)"
							
							let section = DefaultTreeSection(nodeIdentifier: nodeIdentifier, attributedTitle: title.uppercased(), children: rows)
							section.isExpanded = false
							sections.append(section)
						}
						else {
							unknown.append(contentsOf: rows)
						}
					}
					if !unknown.isEmpty {
						unknown.sort { ($0.attributedTitle?.string ?? "") < ($1.attributedTitle?.string ?? "") }
						
						let section = DefaultTreeSection(nodeIdentifier: "-1", title: NSLocalizedString("Unknown Location", comment: "").uppercased(), children: unknown)
						section.isExpanded = false
						sections.append(section)
					}
					sections.sort {$0.nodeIdentifier! < $1.nodeIdentifier!}
				}
			}
		}.then(on: .main) { _ in
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
			
			self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: self.error?.localizedDescription ?? NSLocalizedString("No Results", comment: "")) : nil
			completionHandler()
		}
	}
	
	private var assets: [CachedValue<[ESI.Assets.Asset]>]?
	private var corpAssets: [CachedValue<[ESI.Assets.CorpAsset]>]?
	private var error: Error?
	var contents: [Int64: [NCAsset]]?
	
	//MARK: - NCSearchableViewController
	var searchController: UISearchController?
	
	func updateSearchResults(for searchController: UISearchController) {
		(searchController.searchResultsController as? NCAssetsSearchResultViewController)?.updateSearchResults(for: searchController)
	}
	

}
