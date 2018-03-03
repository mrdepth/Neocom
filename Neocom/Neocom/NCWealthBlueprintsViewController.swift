//
//  NCWealthBlueprintsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.03.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class NCWealthBlueprintsViewController: NCTreeViewController {
//	var assets: [ESI.Assets.Asset]?
	var blueprints: [ESI.Character.Blueprint]?
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

			let rows = self.blueprints?.flatMap { blueprint -> (DefaultTreeRow, Double)? in
				guard let type = invTypes[blueprint.typeID] else {return nil}
				if blueprint.runs > 0 {
					guard let manufacturing = type.blueprintType?.activities?.first(where: {($0 as? NCDBIndActivity)?.activity?.activityID == Int32(NCDBIndActivityID.manufacturing.rawValue)}) as? NCDBIndActivity else {return nil}
					
					let materials = (manufacturing.requiredMaterials as? Set<NCDBIndRequiredMaterial>)?.reduce(0, { (sum, material) -> Double in
						guard let typeID = material.materialType?.typeID else {return sum}
						guard let price = self.prices?[Int(typeID)] else {return sum}
						let count = Int64((Double(material.quantity) * (1.0 - Double(blueprint.materialEfficiency) / 100.0) * 1.0).rounded(.up))
						return sum + Double(count) * price
					}) ?? 0
					
					let products = (manufacturing.products as? Set<NCDBIndProduct>)?.reduce(0, { (sum, product) -> Double in
						guard let typeID = product.productType?.typeID else {return sum}
						guard let price = self.prices?[Int(typeID)] else {return sum}
						return Double(product.quantity) * price
					}) ?? 0
					let total = (products - materials) * Double(blueprint.runs)
					guard total > 0 else {return nil}
					let subtitle = blueprint.runs > 1 ?
						String(format: NSLocalizedString("Products: %@ (per run)\nMaterials: %@ (per run)\nProfit: %@ (for %@ runs)", comment: ""),
						   NCUnitFormatter.localizedString(from: products, unit: .isk, style: .short),
						   NCUnitFormatter.localizedString(from: -materials, unit: .isk, style: .short),
						   NCUnitFormatter.localizedString(from: total, unit: .isk, style: .short),
						   NCUnitFormatter.localizedString(from: blueprint.runs, unit: .none, style: .short))
					:
						String(format: NSLocalizedString("Products: %@ (per run)\nMaterials: %@ (per run)\nProfit: %@ (for 1 run)", comment: ""),
							   NCUnitFormatter.localizedString(from: products, unit: .isk, style: .short),
							   NCUnitFormatter.localizedString(from: -materials, unit: .isk, style: .short),
							   NCUnitFormatter.localizedString(from: total, unit: .isk, style: .short),
							   NCUnitFormatter.localizedString(from: blueprint.runs, unit: .none, style: .short))

					
					let row = DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.default, image: type.icon?.image?.image, title: type.typeName, subtitle: subtitle, accessoryType: .disclosureIndicator, route: Router.Database.TypeInfo(type.objectID))
					return (row, total)
					/*let materials = (manufacturing.requiredMaterials as? Set<NCDBIndRequiredMaterial>)?.flatMap { material -> (DefaultTreeRow, Double)? in
						guard let type = material.materialType else {return nil}
						guard let price = self.prices?[Int(type.typeID)] else {return nil}
						let count = Int64((Double(material.quantity) * (1.0 - Double(blueprint.materialEfficiency) / 100.0) * 1.0).rounded(.up))
						let counts = NCUnitFormatter.localizedString(from: count, unit: .none, style: .short)
						let cost = Double(count) * price
						let costs = NCUnitFormatter.localizedString(from: -cost, unit: .isk, style: .short)
						let subtitle = counts * [NSAttributedStringKey.foregroundColor: UIColor.white] + " \(NSLocalizedString("per run", comment: "")) (" + costs * [NSAttributedStringKey.foregroundColor: UIColor.white] + ")"
						
						return (DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.default, image: type.icon?.image?.image, title: type.typeName, attributedSubtitle: subtitle, accessoryType: .disclosureIndicator, route: Router.Database.TypeInfo(type.objectID)), cost)
					}
					let products = (manufacturing.products as? Set<NCDBIndProduct>)?.flatMap { product -> (DefaultTreeRow, Double)? in
						guard let type = product.productType else {return nil}
						guard let price = self.prices?[Int(type.typeID)] else {return nil}
						let counts = NCUnitFormatter.localizedString(from: product.quantity, unit: .none, style: .short)
						let cost = Double(product.quantity) * price
						let costs = NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .short)
						let subtitle = counts * [NSAttributedStringKey.foregroundColor: UIColor.white] + " \(NSLocalizedString("per run", comment: "")) (" + costs * [NSAttributedStringKey.foregroundColor: UIColor.white] + ")"
						return (DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.default, image: type.icon?.image?.image, title: type.typeName, attributedSubtitle: subtitle, accessoryType: .disclosureIndicator, route: Router.Database.TypeInfo(type.objectID)), cost)
					}
					let meterialsTotal = materials?.reduce(0, {$0 + $1.1}) ?? 0
					let productsTotal = products?.reduce(0, {$0 + $1.1}) ?? 0
					let delta = productsTotal - meterialsTotal
					guard delta > 0 else {return nil}
					let total = delta * Double(blueprint.runs)
					let subtitle =
						(blueprint.runs > 1 ?
							NCUnitFormatter.localizedString(from: delta, unit: .isk, style: .short) * [NSAttributedStringKey.foregroundColor: UIColor.white] + " \(NSLocalizedString("per run", comment: ""))\n" :
							NSAttributedString()) +
						NCUnitFormatter.localizedString(from: total, unit: .isk, style: .short) * [NSAttributedStringKey.foregroundColor: UIColor.white] + " (\(NCUnitFormatter.localizedString(from: blueprint.runs, unit: .none, style: .short)) \(NSLocalizedString("runs", comment: "")))"
					
					var children = [TreeNode]()
					if materials?.isEmpty == false {
						children.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.static, title: "\t\(NSLocalizedString("Materials", comment: "").uppercased()) (\(NCUnitFormatter.localizedString(from: -meterialsTotal, unit: .isk, style: .short)))", isExpandable: false, children: materials?.sorted {$0.1 > $1.1}.map{$0.0}))
					}
					if products?.isEmpty == false {
						children.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.static, title: "\t\(NSLocalizedString("Products", comment: "").uppercased()) (\(NCUnitFormatter.localizedString(from: productsTotal, unit: .isk, style: .short)))", isExpandable: false, children: products?.sorted {$0.1 < $1.1}.map{$0.0}))
					}
					
					
					let row = DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.default, image: type.icon?.image?.image, title: type.typeName, attributedSubtitle: subtitle, accessoryType: .disclosureIndicator, route: Router.Database.TypeInfo(type.objectID))
					row.children = children
					return (row, total)*/
				}
				else if blueprint.runs < 0 {
					guard let price = self.prices?[Int(type.typeID)] else {return nil}
					let subtitle = String(format: NSLocalizedString("Original: %@", comment: ""), NCUnitFormatter.localizedString(from: price, unit: .isk, style: .short))
					let row = DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.default, image: type.icon?.image?.image, title: type.typeName, subtitle: subtitle, accessoryType: .disclosureIndicator, route: Router.Database.TypeInfo(type.objectID))
					return (row, price)
				}
				else {
					return nil
				}

			}.sorted {$0.1 > $1.1}.map{$0.0}
			
			DispatchQueue.main.async {
				self.treeController?.content = RootNode(rows ?? [])
				self.tableView.backgroundView =  self.treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: NSLocalizedString("No Result", comment: ""))

				completionHandler()
			}
		}
	}
}
