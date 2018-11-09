//
//  AssetsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import EVEAPI

class AssetsPresenter: TreePresenter {
	typealias View = AssetsViewController
	typealias Interactor = AssetsInteractor
	typealias Presentation = [Tree.Item.Section<EVELocation, Tree.Item.AssetRow>]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeSectionCell.default,
								  Prototype.TreeDefaultCell.default,
								  Prototype.TreeHeaderCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let treeController = view?.treeController
		return Services.sde.performBackgroundTask { context -> Presentation in
			let itemsIDs = Set(content.value.assets.map {$0.itemID})
			let locationIDs = Set(content.value.assets.map {$0.locationID}).subtracting(itemsIDs)
			
			let typeIDs = content.value.assets.map{$0.typeID}
//			let items = Dictionary(content.value.assets.map { ($0.itemID, $0) }, uniquingKeysWith: { a, _ in a})
			let contents = Dictionary(grouping: content.value.assets, by: {$0.locationID})
			
			let invTypes: [Int: SDEInvType] = typeIDs.isEmpty ? [:] : try {
				let types = try context.managedObjectContext
					.from(SDEInvType.self)
					.filter((\SDEInvType.typeID).in(Set(typeIDs)))
					.all()
					.map {(Int($0.typeID), $0)}
				return Dictionary(types, uniquingKeysWith: { a, _ in a})
			}()
			
			var unknown = [Tree.Item.AssetRow]()
			var sections = [Tree.Item.Section<EVELocation, Tree.Item.AssetRow>]()
			
			for locationID in locationIDs {
				guard var rows = contents[locationID]?.compactMap ({Tree.Item.AssetRow(asset: $0, names: content.value.names, contents: contents, types: invTypes)}) else {continue}
				
				if let location = content.value.locations?[locationID] {
					rows.sort { $0.typeName < $1.typeName }
					let section = Tree.Item.Section(location,
													isExpanded: false,
													diffIdentifier: locationID,
													expandIdentifier: locationID,
													treeController: treeController,
													children: rows)
					sections.append(section)
				}
				else {
					unknown.append(contentsOf: rows)
				}
			}
			sections.sort { ($0.content.solarSystemName ?? "") < ($1.content.solarSystemName ?? "") }
			if !unknown.isEmpty {
				unknown.sort { $0.typeName < $1.typeName }
				let section = Tree.Item.Section(EVELocation.unknown,
												isExpanded: false,
												diffIdentifier: -1,
												expandIdentifier: -1,
												treeController: treeController,
												children: unknown)

				sections.insert(section, at: 0)
			}
			
//			let assets = sections.flatMap { $0.children?.flatMap {$0.flattened} ?? [] }
//			var index = [String: [Tree.Item.AssetRow]]()
//			for asset in assets {
//				for key in asset.searchIndex {
//					index[key, default: []].append(asset)
//				}
//			}
			
			return sections
		}.then(on: .main) { [weak self] presentation -> Presentation in
			(self?.view?.searchController?.searchResultsController as? AssetsSearchResultsViewController)?.input = presentation
			return presentation
		}
	}
}

extension Tree.Item {
	class AssetRow: Tree.Item.Collection<Tree.Content.Default, AnyTreeItem>, Routable {

		let asset: ESI.Assets.Asset
		let typeName: String
		let groupName: String?
		let categoryName: String?
		let name: String?
		var route: Routing?
		
		init?(asset: ESI.Assets.Asset, names: [Int64: ESI.Assets.Name]?, contents: [Int64: [ESI.Assets.Asset]], types: [Int: SDEInvType]) {
			self.asset = asset
			
			guard let type = types[asset.typeID] else {return nil}
			let typeName = type.typeName ?? NSLocalizedString("Unknown Type", comment: "")
			let title: NSAttributedString
			
			if asset.quantity > 1 {
				title = typeName + (" x" + UnitFormatter.localizedString(from: asset.quantity, unit: .none, style: .long)) * [NSAttributedString.Key.foregroundColor: UIColor.caption]
			}
			else {
				title = NSAttributedString(string: typeName)
			}
			self.typeName = typeName

			let children: [AnyTreeItem]?
			let subtitle: String?

			let name = names?[asset.itemID]?.name
			self.name = name
			groupName = type.group?.groupName
			categoryName = type.group?.category?.categoryName

			if let nested = contents[asset.itemID]?.compactMap({AssetRow(asset: $0, names: names, contents: contents, types: types)}),
				!nested.isEmpty {
				let map = Dictionary(grouping: nested, by: {ItemFlag(flag: $0.asset.locationFlag)})
				var rows = map[nil]?.sorted{$0.typeName < $1.typeName}.map{$0.asAnyItem} ?? []
				rows += map.filter {$0.key != nil}.sorted {$0.key!.rawValue < $1.key!.rawValue}.map { (key, value) in
					Tree.Item.Header(Tree.Content.Header(title: key!.title?.uppercased(), image: key!.image.map{Image($0)}), diffIdentifier: Pair(asset, key!), children: value.sorted{$0.typeName < $1.typeName}).asAnyItem
				}
				children = rows
				
				switch(name, nested.isEmpty) {
				case let (name?, false):
					subtitle = String.localizedStringWithFormat(NSLocalizedString("%@ (%@ items)", comment: ""), name, UnitFormatter.localizedString(from: nested.count, unit: .none, style: .long))
				case (nil, false):
					subtitle = String.localizedStringWithFormat(NSLocalizedString("%@ items", comment: ""), UnitFormatter.localizedString(from: nested.count, unit: .none, style: .long))
				case let (name?, true):
					subtitle = name
				default:
					subtitle = nil
				}
			}
			else {
				children = nil
				subtitle = name
			}
			
			route = Router.SDE.invTypeInfo(.objectID(type.objectID))
			
			let content = Tree.Content.Default(attributedTitle: title,
											   subtitle: subtitle,
											   image: Image(type.icon),
											   accessoryType: UITableViewCell.AccessoryType.disclosureIndicator)
			super.init(content, diffIdentifier: asset, children: children)
		}
		
		init(_ other: AssetRow) {
			asset = other.asset
			typeName = other.typeName
			groupName = other.groupName
			categoryName = other.categoryName
			name = other.name
			route = other.route
			super.init(other.content, diffIdentifier: other.diffIdentifier, children: nil)
		}
		
		var flattened: [AssetRow] {
			var result = [self]
			children?.forEach { i in
				if let section = i.base as? Header<AssetRow> {
					(section.children?.flatMap {$0.flattened}).map { result.append(contentsOf: $0) }
				}
				else if let row = i.base as? AssetRow {
					result.append(contentsOf: row.flattened)
				}
			}
			return result
		}
	}
}
