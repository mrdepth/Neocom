//
//  NCFittingAmmoDamageChartViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

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

class NCFittingAmmoDamageChartViewController: UIViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var stepper: UIStepper!
	@IBOutlet weak var chargesStackView: UIStackView!
	@IBOutlet weak var damageChartView: ChartView!

	
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
	
	var charges: [Int] = []

	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		tableView.register([Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCChargeTableViewCell.default])

		guard let category = category else {return}
		guard let group: NCDBDgmppItemGroup = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category) else {return}
		title = group.groupName
		
		guard let ammo = NCAmmoSection(category: category) else {return}
		guard let modules = modules else {return}
		guard let module = modules.first else {return}
		
		damageChartView.axes[.left] = DamageAxis()
		damageChartView.axes[.bottom] = RangeAxis()
		
		/*damageChartView.targetSignature = Double(hullType?.signature ?? 0)
		damageChartView.module = module
		damageChartView.xAxis = Axis(range: 0...0, formatter: NCUnitFormatter(unit: .meter, style: .short))
		damageChartView.yAxis = Axis(range: 0...0, formatter: NCUnitFormatter(unit: .none, style: .short))
		
		damageChartView.updateHandler = { [weak damageChartView] updates in
			let dps = updates.map ({$0.value.dps}).max() ?? 0
			let range = updates.map ({$0.value.range}).max() ?? 0
			damageChartView?.xAxis = Axis(range: 0...range, formatter: NCUnitFormatter(unit: .meter, style: .short))
			damageChartView?.yAxis = Axis(range: 0...dps, formatter: NCUnitFormatter(unit: .none, style: .short))
		}*/
		
		let root = TreeNode()
		root.children = [ammo]
		
		treeController.content = root

	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? NCAmmoNode else {return}
		
		if charges.count >= Limit {
			treeController.deselectCell(for: node, animated: true)
		}
		else {
			let typeID = Int(node.object.typeID)
			charges.append(typeID)
			
			reload()
		}
	}
	
	func treeController(_ treeController: TreeController, didDeselectCellWithNode node: TreeNode) {
		guard let node = node as? NCAmmoNode else {return}

		let typeID = Int(node.object.typeID)
		if let i = charges.index(of: typeID) {
			charges.remove(at: i)
			reload()
		}
		
//		damageChartView.charges = charges
		tableView.reloadRows(at: [], with: .fade)
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
		
		let n = tableView.bounds.size.width / 5
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
				let maxX = ceil((optimal + max(falloff * 3, optimal * 0.5)) / 10000) * 10000
				guard maxX > 0 else {continue}
				let maxDPS = dps(at: optimal * 0.1)
				guard maxDPS > 0 else {return}
				
				size.x = max(size.x, maxX)
				
				
				let path = UIBezierPath()
				var data: [(x: Double, y: Double)] = []
				let dx = maxX / Double(n)
				var x: Double = dx
				
				var y = dps(at:x, signature: targetSignature)
				data.append((x: x, y: y))
				var best = (dps: y, range: x)
				
				size.y = max(size.y, y)

				while x < maxX {
					x += dx
					y = dps(at: x, signature: targetSignature)
					if y > best.dps {
						best = (dps: y, range: x)
					}
					data.append((x: x, y: y))
					size.y = max(size.y, y)

				}
				dataSets[typeID] = data
				
				statistics[typeID] = best
				
			}
			module.charge = charge
			
			DispatchQueue.main.async {

				self.damageChartView.axes[.left]?.range = 0...size.y
				self.damageChartView.axes[.bottom]?.range = 0...size.x

				var charts = self.damageChartView.charts
				
				for (chargeID, data) in dataSets {
					
					
					if let i = charts.index(where: {($0 as? AmmoDamageChart)?.chargeID == chargeID}) {
						let chart = charts[i] as! AmmoDamageChart
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
				
				for chart in charts {
					self.chartColors.append((chart as! AmmoDamageChart).color)
					self.damageChartView.removeChart(chart, animated: true)
				}
				
			}
		}
	}
}
