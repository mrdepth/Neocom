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
	typealias Presentation = [Tree.Item.Section<Tree.Item.AssetRow>]
	
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
			
			let invTypes: [Int: SDEInvType] = !typeIDs.isEmpty ? [:] : try {
				let types = try context.managedObjectContext
					.from(SDEInvType.self)
					.filter((\SDEInvType.typeID).in(typeIDs))
					.all()
					.map {(Int($0.typeID), $0)}
				return Dictionary(types, uniquingKeysWith: { a, _ in a})
			}()
			
			var unknown = [Tree.Item.AssetRow]()
			var sections = [Tree.Item.Section<Tree.Item.AssetRow>]()
			
			for locationID in locationIDs {
				guard var rows = contents[locationID]?.map ({Tree.Item.AssetRow(asset: $0, names: content.value.names, contents: contents, types: invTypes)}) else {continue}
				
				if let location = content.value.locations?[locationID] {
					rows.sort { $0.typeName < $1.typeName }
					let section = Tree.Item.Section(Tree.Content.Section(attributedTitle: location.displayName.uppercased(), isExpanded: false),
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
			sections.sort { ($0.content.attributedTitle?.string ?? "") < ($1.content.attributedTitle?.string ?? "") }
			if !unknown.isEmpty {
				unknown.sort { $0.typeName < $1.typeName }
				let section = Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Unknown Location", comment: "").uppercased(), isExpanded: false),
												diffIdentifier: -1,
												expandIdentifier: -1,
												treeController: treeController,
												children: unknown)

				sections.insert(section, at: 0)
			}
			return sections
		}
	}
}

extension Tree.Item {
	class AssetRow: Tree.Item.ExpandableRow<Tree.Content.Default, AnyTreeItem> {
		let asset: ESI.Assets.Asset
		let typeName: String
		let name: String?
		
		init(asset: ESI.Assets.Asset, names: [Int64: ESI.Assets.Name]?, contents: [Int64: [ESI.Assets.Asset]], types: [Int: SDEInvType]) {
			self.asset = asset
			
			let type = types[asset.typeID]
			let typeName = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
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

			if let nested = contents[asset.itemID]?.map({AssetRow(asset: $0, names: names, contents: contents, types: types)}),
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
			
			
			let content = Tree.Content.Default(attributedTitle: title,
											   subtitle: subtitle,
											   image: Image(type?.icon),
											   accessoryType: UITableViewCell.AccessoryType.disclosureIndicator)

			super.init(content, diffIdentifier: asset, isExpanded: true, children: children)
		}
	}
}
