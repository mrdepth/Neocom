//
//  NCFittingModuleDamageChartTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import Dgmpp

class NCFittingModuleDamageChartTableViewCell: NCTableViewCell {
//	@IBOutlet weak var damageChartView: NCFittingModuleDamageChartView!
	@IBOutlet weak var damageChartView: ChartView!
	@IBOutlet weak var optimalLabel: UILabel!
	@IBOutlet weak var falloffLabel: UILabel!
	@IBOutlet weak var rawDpsLabel: UILabel!
	@IBOutlet weak var dpsLabel: UILabel!
	@IBOutlet weak var dpsAccuracyView: UIView!
	@IBOutlet weak var stepper: UIStepper!
}


extension Prototype {
	enum NCFittingModuleDamageChartTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCFittingModuleDamageChartTableViewCell")
	}
}

class NCFittingModuleDamageChartRow: TreeRow {
	let module: DGMModule
	let ship: DGMShip?
	let count: Int
	
	lazy var hullTypes: [NCDBDgmppHullType]? = {
		let request = NSFetchRequest<NCDBDgmppHullType>(entityName: "DgmppHullType")
		request.sortDescriptors = [NSSortDescriptor(key: "signature", ascending: true), NSSortDescriptor(key: "hullTypeName", ascending: true)]
		return (try? NCDatabase.sharedDatabase!.viewContext.fetch(request))

	}()
	
	lazy var hullType: NCDBDgmppHullType? = {
		guard let ship = self.ship else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[ship.typeID]?.hullType
	}()
	
	init(module: DGMModule, count: Int) {
		self.module = module
		self.ship = module.parent as? DGMShip
		self.count = count
		super.init(prototype: Prototype.NCFittingModuleDamageChartTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingModuleDamageChartTableViewCell else {return}
//		cell.damageChartView.module = self.module
		cell.stepper.maximumValue = Double(hullTypes?.count ?? 1) - 1
		cell.object = self
		if let hullType = hullType {
			cell.stepper.value = Double(hullTypes?.index(of: hullType) ?? 0)
		}
		cell.dpsLabel.text = NSLocalizedString("DPS AGAINST", comment: "") + " " + (hullType?.hullTypeName?.uppercased() ?? "")
		let targetSignature = DGMMeter(hullType?.signature ?? 0)
//		cell.damageChartView.targetSignature = targetSignature
		
		let n = Double(round((treeController?.tableView?.bounds.size.width ?? 320) / 5))
		
		guard n > 0 else {return}
		guard let ship = ship else {return}
		let module = self.module
		
		var hitChanceData = [(x: Double, y: Double)]()
		var dpsData = [(x: Double, y: Double)]()
		//			let hitChancePath = UIBezierPath()
		//			let dpsPath = UIBezierPath()
		
		let optimal = module.optimal
		let falloff = module.falloff
		let maxX = ceil((optimal + max(falloff * 2, optimal * 0.5)) / 10000) * 10000
		guard maxX > 0 else {return}
		let dx = maxX / n
		
		func dps(at range: Double, signature: Double = 0) -> Double {
			let angularVelocity = signature > 0 ? ship.maxVelocityInOrbit(range) * DGMSeconds(1) / range : 0
			let dps =  module.dps(target: DGMHostileTarget(angularVelocity: DGMRadiansPerSecond(angularVelocity), velocity: DGMMetersPerSecond(0), signature: signature, range: range))
			return (dps * DGMSeconds(1)).total
		}
		
		let maxDPS = dps(at: optimal * 0.1)
		guard maxDPS > 0 else {return}
		
		var x: Double = dx
		hitChanceData.append((x: 0, y: maxDPS))
		hitChanceData.append((x: dx, y: maxDPS))
		dpsData.append((x: x, y: dps(at:x, signature: targetSignature)))
		
		x += dx
		while x < maxX {
			hitChanceData.append((x: x, y: dps(at: x)))
			dpsData.append((x: x, y: dps(at:x, signature: targetSignature)))
			x += dx
		}
		
		x = optimal
		let optimalData = [(x: x, y: 0), (x: x, y: dps(at: x))]
		
		x = optimal + falloff
		let falloffData = [(x: x, y: 0), (x: x, y: dps(at: x))]
		
		let accuracy = module.accuracy(targetSignature: targetSignature)
		
		let totalDPS = (module.dps() * DGMSeconds(1)).total
		
		//			DispatchQueue.main.async {
//		guard (cell.object as? NCFittingModuleDamageChartRow) == self else {return}
		
		let xRange = 0...maxX
		let yRange = 0...maxDPS
		if cell.damageChartView.charts.isEmpty {
			let dpsChart = LineChart()
			dpsChart.color =  accuracy.color
			dpsChart.data = dpsData
			dpsChart.xRange = xRange
			dpsChart.yRange = yRange
			
			let accuracyChart = LineChart()
			accuracyChart.color =  .caption
			accuracyChart.data = hitChanceData
			accuracyChart.xRange = xRange
			accuracyChart.yRange = yRange
			
			let optimalChart = LineChart()
			optimalChart.color =  UIColor(white: 1.0, alpha: 0.3)
			optimalChart.data = optimalData
			optimalChart.xRange = xRange
			optimalChart.yRange = yRange
			
			let falloffChart = LineChart()
			falloffChart.color =  UIColor(white: 1.0, alpha: 0.3)
			falloffChart.data = falloffData
			falloffChart.xRange = xRange
			falloffChart.yRange = yRange
			
			cell.damageChartView.addChart(dpsChart, animated: true)
			cell.damageChartView.addChart(accuracyChart, animated: true)
			cell.damageChartView.addChart(optimalChart, animated: true)
			cell.damageChartView.addChart(falloffChart, animated: true)
		}
		else {
			var chart = (cell.damageChartView.charts[0] as? LineChart)
			chart?.color = accuracy.color
			chart?.xRange = xRange
			chart?.yRange = yRange
			chart?.data = dpsData
			
			chart = (cell.damageChartView.charts[1] as? LineChart)
			chart?.xRange = xRange
			chart?.yRange = yRange
			chart?.data = hitChanceData
			
			chart = (cell.damageChartView.charts[2] as? LineChart)
			chart?.xRange = xRange
			chart?.yRange = yRange
			chart?.data = optimalData
			
			chart = (cell.damageChartView.charts[3] as? LineChart)
			chart?.xRange = xRange
			chart?.yRange = yRange
			chart?.data = falloffData
		}
		
		cell.dpsAccuracyView.backgroundColor = accuracy.color
		if self.count > 1 {
			cell.rawDpsLabel.text = NSLocalizedString("RAW DPS:", comment: "") + " " + NCUnitFormatter.localizedString(from: totalDPS, unit: .none, style: .full) + " x \(self.count) = " + NCUnitFormatter.localizedString(from: totalDPS * Double(self.count), unit: .none, style: .full)
		}
		else {
			cell.rawDpsLabel.text = NSLocalizedString("RAW DPS:", comment: "") + " " + NCUnitFormatter.localizedString(from: totalDPS * Double(self.count), unit: .none, style: .full)
		}
		cell.optimalLabel.text = NSLocalizedString("Optimal", comment: "") + "\n" + NCUnitFormatter.localizedString(from: optimal, unit: .meter, style: .full)
		if falloff > 0 {
			cell.falloffLabel.text = NSLocalizedString("Falloff", comment: "") + "\n" + NCUnitFormatter.localizedString(from: optimal + falloff, unit: .meter, style: .full)
		}
		else {
			cell.falloffLabel.isHidden = true
		}
		
		if let constraint = cell.optimalLabel.superview?.constraints.first(where: {$0.firstItem === cell.optimalLabel && $0.secondItem === cell.optimalLabel.superview && $0.firstAttribute == .centerX}) {
			let m = maxX > 0 ? max(0.01, optimal / maxX) : 0.01
			constraint.isActive = false
			let other = NSLayoutConstraint(item: cell.optimalLabel, attribute: .centerX, relatedBy: .equal, toItem: cell.optimalLabel.superview, attribute: .trailing, multiplier: CGFloat(m), constant: 0)
			other.priority = constraint.priority
			other.isActive = true
		}
		if let constraint = cell.falloffLabel.superview?.constraints.first(where: {$0.firstItem === cell.falloffLabel && $0.secondItem === cell.falloffLabel.superview && $0.firstAttribute == .centerX}) {
			let m = maxX > 0 ? max(0.01, (optimal + falloff) / maxX) : 0.01
			constraint.isActive = false
			let other = NSLayoutConstraint(item: cell.falloffLabel, attribute: .centerX, relatedBy: .equal, toItem: cell.falloffLabel.superview, attribute: .trailing, multiplier: CGFloat(m), constant: 0)
			other.priority = constraint.priority
			other.isActive = true
		}
		
		//			}
		
	}
	
	override var hashValue: Int {
		return module.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingModuleDamageChartRow)?.hashValue == hashValue
	}
	
}
