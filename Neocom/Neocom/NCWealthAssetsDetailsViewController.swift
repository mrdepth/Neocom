//
//  NCWealthAssetsDetailsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.03.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class NCWealthAssetsDetailsViewController: NCTreeViewController {
	var assets: [ESI.Assets.Asset]?
	var prices: [Int: Double]?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.default,
							Prototype.NCHeaderTableViewCell.static,
							Prototype.NCHeaderTableViewCell.empty])
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
			let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
			
			var types = [Int: Int]()
			self.assets?.forEach { types[$0.typeID, default: 0] += $0.quantity }
			
			let rows = types.flatMap { (typeID, quantity) -> (DefaultTreeRow, Double)? in
				guard let type = invTypes[typeID] else {return nil}
				let price = self.prices?[typeID] ?? 0
				let cost = price * Double(quantity)
				
				let title: NSAttributedString
				let subtitle: String
				if quantity > 1 {
					title = (type.typeName ?? "") + (" x" + NCUnitFormatter.localizedString(from: quantity, unit: .none, style: .full)) * [NSAttributedStringKey.foregroundColor: UIColor.caption]
					subtitle = String(format: NSLocalizedString("%@ (%@ per unit)", comment: ""), NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .short), NCUnitFormatter.localizedString(from: price, unit: .isk, style: .short))
//					subtitle = NCUnitFormatter.localizedString(from: price, unit: .isk, style: .short) * [NSAttributedStringKey.foregroundColor: UIColor.white] + " \(NSLocalizedString("per unit", comment: ""))\n" +
//						NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .short) * [NSAttributedStringKey.foregroundColor: UIColor.white] + " (\(NCUnitFormatter.localizedString(from: quantity, unit: .none, style: .short)) \(NSLocalizedString("units", comment: "")))"
				}
				else {
					title = NSAttributedString(string: type.typeName ?? "")
					subtitle = NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .short)
//					subtitle = NCUnitFormatter.localizedString(from: price, unit: .isk, style: .short) * [NSAttributedStringKey.foregroundColor: UIColor.white]
				}

				
				return (DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.default, image: type.icon?.image?.image, attributedTitle: title, subtitle: subtitle, accessoryType: .disclosureIndicator, route: Router.Database.TypeInfo(type.objectID)), cost)
			}.sorted {$0.1 > $1.1}.map{$0.0}
			
			DispatchQueue.main.async {
				self.treeController?.content = RootNode(rows)
				self.tableView.backgroundView =  self.treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: NSLocalizedString("No Result", comment: ""))
				
				completionHandler()
			}
		}
	}
}
