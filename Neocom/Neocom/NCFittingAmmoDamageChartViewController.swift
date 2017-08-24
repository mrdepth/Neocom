//
//  NCFittingAmmoDamageChartViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

fileprivate let Limit = 5

class DamageAxis: ChartAxis {
	let formatter = NCUnitFormatter(unit: .none, style: .short)
	override func title(for x: Double) -> String {
		return formatter.string(for: x) ?? "\(x)"
	}
}

class RangeAxis: ChartAxis {
	let formatter = NCUnitFormatter(unit: .meter, style: .short)
	override func title(for x: Double) -> String {
		return formatter.string(for: x) ?? "\(x)"
	}
}

class AmmoDamageChart: LineChart {
	let chargeID: Int
	
	init(chargeID: Int) {
		self.chargeID = chargeID
		super.init()
	}
}

class NCAmmoDamageChartNode: NCAmmoNode {
	var isSelected: Bool = false
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		cell.backgroundColor = isSelected ? UIColor.separator : UIColor.cellBackground
	}
}

class NCFittingAmmoDamageChartViewController: UIViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var stepper: UIStepper!
	@IBOutlet weak var chargesStackView: UIStackView!
	@IBOutlet weak var damageChartView: ChartView!
	@IBOutlet weak var hullLabel: UILabel!
	@IBOutlet weak var hullTypeStepper: UIStepper!

	
	var category: NCDBDgmppItemCategory?
	var modules: [NCFittingModule]?
	
	lazy var hullType: NCDBDgmppHullType? = {
		guard let module = self.modules?.first else {return nil}
		var hullType: NCDBDgmppHullType?
		module.engine?.performBlockAndWait {
			guard let ship = module.owner as? NCFittingShip else {return}
			hullType = NCDatabase.sharedDatabase?.invTypes[ship.typeID]?.hullType
		}
		return hullType
	}()

	private lazy var hullTypes: [NCDBDgmppHullType]? = {
		let request = NSFetchRequest<NCDBDgmppHullType>(entityName: "DgmppHullType")
		request.sortDescriptors = [NSSortDescriptor(key: "signature", ascending: true), NSSortDescriptor(key: "hullTypeName", ascending: true)]
		return (try? NCDatabase.sharedDatabase!.viewContext.fetch(request))
		
	}()

	var charges: [Int] = [] {
		didSet {
			self.title = "\(charges.count) / \(Limit)"
			self.navigationItem.rightBarButtonItem?.isEnabled = charges.count > 0
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		charges = []
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		tableView.register([Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCChargeTableViewCell.default])

		guard let category = category else {return}
		guard let group: NCDBDgmppItemGroup = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category) else {return}
		title = group.groupName
		
		guard let ammo = NCAmmoSection(category: category, objectNode: NCAmmoDamageChartNode.self) else {return}
		
		damageChartView.axes[.left] = DamageAxis()
		damageChartView.axes[.bottom] = RangeAxis()
		
		hullLabel.text = NSLocalizedString("DPS AGAINST", comment: "") + " " + (hullType?.hullTypeName?.uppercased() ?? "")
		hullTypeStepper.maximumValue = Double(hullTypes?.count ?? 1) - 1
		if let hullType = hullType {
			hullTypeStepper.value = Double(hullTypes?.index(of: hullType) ?? 0)
		}

		treeController.content = ammo

	}
	
	@IBAction func onChangeHullType(_ sender: UIStepper) {
		hullType = hullTypes?[Int(sender.value)]
		hullLabel.text = NSLocalizedString("DPS AGAINST", comment: "") + " " + (hullType?.hullTypeName?.uppercased() ?? "")
		reload()
	}

	@IBAction func onClear(_ sender: Any) {
		charges = []
		reload()
//		treeController.selectedNodes().forEach {treeController.deselectCell(for: $0, animated: true)}
		for section in treeController.content?.children ?? [] {
			for child in section.children {
				(child as? NCAmmoDamageChartNode)?.isSelected = false
			}
		}
		tableView.reloadData()
	}

	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? NCAmmoDamageChartNode else {return}
		if node.isSelected {
			let typeID = Int(node.object.typeID)
			if let i = charges.index(of: typeID) {
				charges.remove(at: i)
				reload()
			}
			node.isSelected = false
			treeController.reloadCells(for: [node], with: .none)
		}
		else {
			if charges.count < Limit {
				let typeID = Int(node.object.typeID)
				charges.append(typeID)
				reload()
				node.isSelected = true
				treeController.reloadCells(for: [node], with: .none)
			}
			else {
				treeController.deselectCell(for: node, animated: true)
			}
		}
	}
	
	/*func treeController(_ treeController: TreeController, didDeselectCellWithNode node: TreeNode) {
		guard let node = node as? NCAmmoNode else {return}

	}*/
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let node = node as? NCAmmoNode else {return}
		Router.Database.TypeInfo(node.object).perform(source: self, sender: treeController.cell(for: node))
	}
	
	
	//MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCDatabaseTypeInfoViewController"?:
			guard let controller = segue.destination as? NCDatabaseTypeInfoViewController,
				let cell = sender as? NCTableViewCell,
				let type = cell.object as? NCDBInvType else {
					return
			}
			controller.type = type
		default:
			break
		}
	}
	
	private var chartColors: [UIColor] = {
		var colors = [UIColor]()
		
		
		for i in 0..<Limit {
			colors.append(UIColor(hue: CGFloat(i) / CGFloat(Limit), saturation: 0.5, brightness: 1.0, alpha: 1.0))
		}
		
		return colors
	}()
	
	private func reload() {
		guard let module = modules?.first else {return}
		let charges = self.charges
		
		let n = tableView.bounds.size.width
		let targetSignature = Double(hullType?.signature ?? 0)

		module.engine?.perform {
			guard let ship = module.owner as? NCFittingShip else {return}
			let charge = module.charge
			
			func dps(at range: Double, signature: Double = 0) -> Double {
				let angularVelocity = signature > 0 ? ship.maxVelocity(orbit: range) / range : 0
				return module.dps(target: NCFittingHostileTarget(angularVelocity: angularVelocity, velocity: 0, signature: signature, range: range)).total
			}
			
			var dataSets = [Int: [(x: Double, y: Double)]]()
			var size: (x: Double, y: Double) = (x: 0, y: 0)
			
			var statistics = [Int: (dps: Double, range: Double)]()
			
			for typeID in charges {
				module.charge = NCFittingCharge(typeID: typeID)
				let optimal = module.maxRange
				let falloff = module.falloff
				let maxX = ceil((optimal + max(falloff * 2, optimal * 0.5)) / 10000) * 10000
				let maxY = dps(at: optimal * 0.1)
				size.x = max(size.x, maxX)
				size.y = max(size.y, maxY)
			}
			
			for typeID in charges {
				module.charge = NCFittingCharge(typeID: typeID)
				
				let maxX = size.x
				guard maxX > 0 else {continue}
				
				var data: [(x: Double, y: Double)] = []
				let dx = maxX / Double(n)
				var x: Double = dx
				
				var y = dps(at:x, signature: targetSignature)
				data.append((x: x, y: y))
				var best = (dps: y, range: x)
				
//				size.y = max(size.y, y)
				x += dx

				while x < maxX {
					y = dps(at: x, signature: targetSignature)
					if y > best.dps {
						best = (dps: y, range: x)
					}
					data.append((x: x, y: y))
//					size.y = max(size.y, y)
					x += dx
				}
				dataSets[typeID] = data
				
				statistics[typeID] = best
				
			}
			module.charge = charge
			
			DispatchQueue.main.async {

				self.damageChartView.axes[.left]?.range = 0...size.y
				self.damageChartView.axes[.bottom]?.range = 0...size.x

				var charts = self.damageChartView.charts as! [AmmoDamageChart]
				
				for (chargeID, data) in dataSets {
					
					
					if let i = charts.index(where: {$0.chargeID == chargeID}) {
						let chart = charts[i]
						charts.remove(at: i)
						chart.xRange = 0...size.x
						chart.yRange = 0...size.y
						chart.data = data
					}
					else {
						let chart = AmmoDamageChart(chargeID: chargeID)
						chart.color = self.chartColors.removeFirst()
						chart.xRange = 0...size.x
						chart.yRange = 0...size.y
						chart.data = data
						self.damageChartView.addChart(chart, animated: true)
					}
				}
				
				var labels = self.chargesStackView.arrangedSubviews as! [UILabel]
				let invTypes = NCDatabase.sharedDatabase?.invTypes
				let count = Double(self.modules?.count ?? 0)

				for chart in charts {
					self.chartColors.insert(chart.color, at: 0)
					self.damageChartView.removeChart(chart, animated: true)
				}

				UIView.animate(withDuration: 0.25, animations: {
					for chart in self.damageChartView.charts as! [AmmoDamageChart] {
						let label = labels.count > 0 ? labels.removeFirst() : {
							let label = UILabel()
							label.font = UIFont.preferredFont(forTextStyle: .footnote)
							self.chargesStackView.addArrangedSubview(label)
							return label
							}()
						let best = statistics[chart.chargeID]!
						let dps = NCUnitFormatter.localizedString(from: best.dps * count, unit: .none, style: .full)
						let range = NCUnitFormatter.localizedString(from: best.range, unit: .meter, style: .full)
						
						let typeName = invTypes?[chart.chargeID]?.typeName ?? ""
						label.text = "\(typeName) (\(dps) \(NSLocalizedString("at", comment: "DPS at range")) \(range))"
						label.textColor = chart.color
					}
					labels.forEach {$0.removeFromSuperview()}
					self.view.setNeedsLayout()
					self.view.layoutIfNeeded()
				})
				

			}
		}
	}
}
