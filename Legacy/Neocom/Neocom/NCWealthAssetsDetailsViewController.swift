//
//  NCWealthAssetsDetailsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.03.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Futures

class NCWealthAssetsDetailsViewController: NCTreeViewController {
	var assets: [ESI.Assets.Asset]?
	var prices: [Int: Double]?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.default,
							Prototype.NCHeaderTableViewCell.static,
							Prototype.NCHeaderTableViewCell.empty])
	}
	
	override func content() -> Future<TreeNode?> {
		return NCDatabase.sharedDatabase!.performBackgroundTask { managedObjectContext -> TreeNode? in
			let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
			
			var types = [Int: Int]()
			self.assets?.forEach { types[$0.typeID, default: 0] += $0.quantity }
			
			let rows = types.compactMap { (typeID, quantity) -> (DefaultTreeRow, Double)? in
				guard let type = invTypes[typeID] else {return nil}
				let price = self.prices?[typeID] ?? 0
				let cost = price * Double(quantity)
				
				let title: NSAttributedString
				let subtitle: String
				if quantity > 1 {
					title = (type.typeName ?? "") + (" x" + NCUnitFormatter.localizedString(from: quantity, unit: .none, style: .full)) * [NSAttributedStringKey.foregroundColor: UIColor.caption]
					subtitle = String(format: NSLocalizedString("%@ (%@ per unit)", comment: ""), NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .short), NCUnitFormatter.localizedString(from: price, unit: .isk, style: .short))
				}
				else {
					title = NSAttributedString(string: type.typeName ?? "")
					subtitle = NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .short)
				}

				
				return (DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.default, image: type.icon?.image?.image, attributedTitle: title, subtitle: subtitle, accessoryType: .disclosureIndicator, route: Router.Database.TypeInfo(type.objectID)), cost)
			}.sorted {$0.1 > $1.1}.map{$0.0}
			
			guard !rows.isEmpty else {throw NCTreeViewControllerError.noResult}
			return RootNode(rows)
		}
	}
}
