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
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		pieChartRow = NCPieChartRow(formatter: NCUnitFormatter(unit: .isk, style: .short))
		detailsSection = TreeNode()

		treeController?.content = RootNode([pieChartRow!, detailsSection!])
		
		NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
			let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
			var ships = 0.0
			var modules = 0.0
			var charges = 0.0
			var drones = 0.0
			var materials = 0.0
			var other = 0.0
			
			for asset in self.assets ?? [] {
				guard let category = invTypes[asset.typeID]?.group?.category, let price = self.prices?[asset.typeID] else {continue}
				switch NCDBCategoryID(rawValue: Int(category.categoryID)) {
				case .ship?:
					ships += Double(asset.quantity ?? 1) * price
				case .module?, .subsystem?:
					modules += Double(asset.quantity ?? 1) * price
				case .charge?:
					charges += Double(asset.quantity ?? 1) * price
				case .drone?:
					drones += Double(asset.quantity ?? 1) * price
				case .asteroid?, .ancientRelic?, .material?, .planetaryResource?, .reaction?:
					materials += Double(asset.quantity ?? 1) * price
				default:
					other += Double(asset.quantity ?? 1) * price
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
					if value > 0 {
						let segment = PieSegment(value: value, color: color, title: title)
						self.pieChartRow?.add(segment: segment)
						rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: title, title: title.uppercased(), subtitle: NCUnitFormatter.localizedString(from: value, unit: .isk, style: .full)))
					}
				}
				
				self.detailsSection?.children = rows
				completionHandler()
			}
		}
	}
	
	
	//MARK: - Private
	
}
