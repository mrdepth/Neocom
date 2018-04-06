//
//  NCWealthAssetsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCWealthAssetsViewController: NCTreeViewController {
	
	var assets: [ESI.Assets.Asset]?
	var prices: [Int: Double]?
	
	private var pieChartRow: NCPieChartRow?
	private var detailsSection: TreeNode?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.attribute,
		                    Prototype.NCPieChartTableViewCell.default])
		
		
	}
	
	override func content() -> Future<TreeNode?> {
		pieChartRow = NCPieChartRow(formatter: NCUnitFormatter(unit: .isk, style: .short))
		detailsSection = TreeNode()

		NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
			let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
			var ships: (Double, [ESI.Assets.Asset]) = (0.0, [])
			var modules: (Double, [ESI.Assets.Asset]) = (0.0, [])
			var charges: (Double, [ESI.Assets.Asset]) = (0.0, [])
			var drones: (Double, [ESI.Assets.Asset]) = (0.0, [])
			var materials: (Double, [ESI.Assets.Asset]) = (0.0, [])
			var other: (Double, [ESI.Assets.Asset]) = (0.0, [])
			
			for asset in self.assets ?? [] {
				guard let category = invTypes[asset.typeID]?.group?.category, let price = self.prices?[asset.typeID] else {continue}
				switch NCDBCategoryID(rawValue: Int(category.categoryID)) {
				case .ship?:
					ships.0 += Double(asset.quantity) * price
					ships.1.append(asset)
				case .module?, .subsystem?:
					modules.0 += Double(asset.quantity) * price
					modules.1.append(asset)
				case .charge?:
					charges.0 += Double(asset.quantity) * price
					charges.1.append(asset)
				case .drone?:
					drones.0 += Double(asset.quantity) * price
					drones.1.append(asset)
				case .asteroid?, .ancientRelic?, .material?, .planetaryResource?, .reaction?:
					materials.0 += Double(asset.quantity) * price
					materials.1.append(asset)
				default:
					other.0 += Double(asset.quantity) * price
					other.1.append(asset)
				}
			}
			DispatchQueue.main.async {
				var rows: [DefaultTreeRow] = []
				let list = [
					(ships, NSLocalizedString("Ships", comment: ""), UIColor.green),
					(modules, NSLocalizedString("Modules", comment: ""), UIColor.cyan),
					(charges, NSLocalizedString("Charges", comment: ""), UIColor.orange),
					(drones, NSLocalizedString("Drones", comment: ""), UIColor.red),
					(materials, NSLocalizedString("Materials", comment: ""), UIColor.yellow),
					(other, NSLocalizedString("Other", comment: ""), UIColor(white: 0.9, alpha: 1.0))
				]
				for (value, title, color) in list {
					if value.0 > 0 {
						let segment = PieSegment(value: value.0, color: color, title: title)
						self.pieChartRow?.add(segment: segment)
						let route = Router.Wealth.AssetsDetails(assets: value.1, prices: self.prices ?? [:], title: title)
						rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: title, title: title.uppercased(), subtitle: NCUnitFormatter.localizedString(from: value.0, unit: .isk, style: .full), accessoryType: .disclosureIndicator, route: route))
					}
				}
				
				self.detailsSection?.children = rows
			}
		}
		return .init(RootNode([pieChartRow!, detailsSection!]))
	}
	
	
	//MARK: - Private
	
}
