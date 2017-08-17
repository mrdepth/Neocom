//
//  NCPlanetaryViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

enum NCColonyError: Error {
	case invalidLayout
}

class NCColonySection: TreeSection {
	let colony: ESI.PlanetaryInteraction.Colony
	let layout: NCCachedResult<ESI.PlanetaryInteraction.ColonyLayout>
	let engine: NCFittingEngine
	
	lazy var planet: NCDBMapDenormalize? = {
		return NCDatabase.sharedDatabase?.mapDenormalize[self.colony.planetID]
	}()
	
	init(colony: ESI.PlanetaryInteraction.Colony, layout: NCCachedResult<ESI.PlanetaryInteraction.ColonyLayout>, engine: NCFittingEngine) {
		self.colony = colony
		self.layout = layout
		self.engine = engine
		super.init(prototype: Prototype.NCHeaderTableViewCell.default)
	}
	
	override var hashValue: Int {
		return colony.hashValue ^ (layout.value?.hashValue ?? 0)
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCColonySection)?.hashValue == hashValue
	}
	
	override func loadChildren() {
		if let layout = layout.value {
			self.children = []
			let colony = self.colony
			let engine = self.engine
			let planetTypeID = Int(self.planet?.type?.typeID ?? 0)

			engine.perform {
				
				do {
					let planet = NCFittingPlanet(typeID: planetTypeID)
					engine.planet = planet
					
					
					for pin in layout.pins {
						guard planet.facility(identifier: pin.pinID) == nil,
							let facility = planet.addFacility(typeID: pin.typeID, identifier: pin.pinID) else {throw NCColonyError.invalidLayout}
						
						switch facility {
						case let ecu as NCFittingExtractorControlUnit:
							ecu.launchTime = pin.lastCycleStart?.timeIntervalSinceReferenceDate ?? 0
							ecu.installTime = pin.installTime?.timeIntervalSinceReferenceDate ?? 0
							ecu.expiryTime = pin.expiryTime?.timeIntervalSinceReferenceDate ?? 0
							ecu.cycleTime = TimeInterval(pin.extractorDetails?.cycleTime ?? 0)
							ecu.quantityPerCycle = pin.extractorDetails?.qtyPerCycle ?? 0
//							ecu.quantityPerCycle *= 2
						case let factory as NCFittingIndustryFacility:
							factory.launchTime = pin.lastCycleStart?.timeIntervalSinceReferenceDate ?? 0
							if let schematicID = pin.schematicID {
								factory.schematic = NCFittingSchematic(schematicID: schematicID)
							}
							
						default:
							break
						}
					}
					
//					planet.facility(identifier: 1020196651494)?.addCommodity(typeID: 2267, quantity: 209063)
//					planet.facility(identifier: 1020196651494)?.addCommodity(typeID: 2396, quantity: 3060)
//					planet.facility(identifier: 1020196651502)?.addCommodity(typeID: 2288, quantity: 249)
//					planet.facility(identifier: 1020196651506)?.addCommodity(typeID: 2270, quantity: 2776)
//					planet.facility(identifier: 1020196651508)?.addCommodity(typeID: 2396, quantity: 40)
//					planet.facility(identifier: 1020196651514)?.addCommodity(typeID: 2329, quantity: 245)
					
					for route in layout.routes {
						guard let source = planet.facility(identifier: route.sourcePinID),
							let destination = planet.facility(identifier: route.destinationPinID) else {throw NCColonyError.invalidLayout}
						
						planet.addRoute(from: source, to: destination, commodity: NCFittingCommodity(contentType: route.contentTypeID, quantity: Int(route.quantity), engine: engine), identifier: route.routeID)
					}
					
					let lastUpdate = colony.lastUpdate
					planet.lastUpdate = lastUpdate.timeIntervalSinceReferenceDate
					
					planet.simulate()
					
					let currentTime = Date().timeIntervalSinceReferenceDate
					var rows = planet.facilities.flatMap { i -> NCFacilityRow? in
						switch i {
						case let facility as NCFittingExtractorControlUnit:
							return NCExtractorControlUnitRow(extractor: facility, currentTime: currentTime)
						case let facility as NCFittingIndustryFacility:
							return NCFactoryRow(factory: facility, currentTime: currentTime)
						case let facility as NCFittingStorageFacility:
							return NCStorageRow(storage: facility, currentTime: currentTime)
						default:
							return nil
						}
					}
					
					rows.sort(by: {$0.sortDescriptor < $1.sortDescriptor})
					DispatchQueue.main.async {
						self.children = rows
					}
				}
				catch {
					DispatchQueue.main.async {
						self.children = [DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, title: error.localizedDescription)]
					}
				}


			}
		}
		else if let error = layout.error {
			self.children = [DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, title: error.localizedDescription)]
		}
		else {
			self.children = [DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, title: NSLocalizedString("Colony Layout is Not Available", comment: ""))]
		}
		super.loadChildren()
		
	}
	
	lazy var title: NSAttributedString? = {
		let solarSystem = NCDatabase.sharedDatabase?.mapSolarSystems[self.colony.solarSystemID]
		let location = NCDatabase.sharedDatabase?.mapDenormalize[self.colony.planetID]?.itemName ?? solarSystem?.solarSystemName ?? NSLocalizedString("Unknown", comment: "")
		if let solarSystem = solarSystem {
			let security = solarSystem.security
			return (String(format: "%.1f ", security) * [NSForegroundColorAttributeName: UIColor(security: security)] + location + " (\(self.colony.planetType.title))").uppercased()
		}
		else {
			return (location + " (\(self.colony.planetType.title))").uppercased() * [:]
		}
	}()
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		
		cell.titleLabel?.attributedText = title
	}
}

class NCFacilityRow: TreeRow {
	let typeID: Int
	let sortDescriptor: String
	let facilityName: String
	let identifier: Int64
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.typeID]
	}()
	
	init(prototype: Prototype, facility: NCFittingFacility) {
		typeID = facility.typeID
		facilityName = facility.facilityName
		identifier = facility.identifier
		switch facility {
		case is NCFittingExtractorControlUnit:
			sortDescriptor = "0\(facility.typeName)\(facilityName)"
		case is NCFittingStorageFacility:
			sortDescriptor = "1\(facility.typeName)\(facilityName)"
		case is NCFittingIndustryFacility:
			sortDescriptor = "2\(facility.typeName)\(facilityName)"
		default:
			sortDescriptor = "3\(facility.typeName)\(facilityName)"
		}
		super.init(prototype: prototype, accessoryButtonRoute: Router.Database.TypeInfo(facility.typeID))
		isExpandable = true
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.attributedText = (type?.typeName ?? "") + " \(facilityName)" * [NSForegroundColorAttributeName: UIColor.caption]
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.accessoryType = .detailButton
	}
	
	override var hashValue: Int {
		return identifier.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFacilityRow)?.hashValue == hashValue
	}

}

class NCFacilityOutputRow: TreeRow {
	let typeID: Int
	let identifier: Int64

	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.typeID]
	}()

	init(typeID: Int, identifier: Int64) {
		self.typeID = typeID
		self.identifier = identifier
		super.init(prototype: Prototype.NCDefaultTableViewCell.attribute, route: Router.Database.TypeInfo(typeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = NSLocalizedString("Output", comment: "").uppercased()
		cell.subtitleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.accessoryType = .disclosureIndicator
	}
	
	override var hashValue: Int {
		return [identifier, typeID].hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFacilityOutputRow)?.hashValue == hashValue
	}

}

class NCExtractorControlUnitRow: NCFacilityRow {

	let wasteState: NCFittingProductionState?
	let currentTime: TimeInterval
	let yield: Int
	let waste: Int
	let extractor: NCFittingExtractorControlUnit
	
	init(extractor: NCFittingExtractorControlUnit, currentTime: TimeInterval) {
		self.currentTime = currentTime
		self.extractor = extractor
		
		let states = (extractor.states as? [NCFittingProductionState])?.flatMap { state -> (BarChart.Item)? in
			guard let cycle = state.currentCycle as? NCFittingProductionCycle else {return nil}
			let yield = Double(cycle.yield.quantity)
			let waste = Double(cycle.waste.quantity)
			let launchTime = Double(state.timestamp)

			let total = yield + waste
			let f = total > 0 ? yield / total : 1
			return BarChart.Item(x: launchTime, y: total, f: f)
		} ?? []
		
		let xRange: ClosedRange<TimeInterval>
		if let from = states.first?.x, let to = states.last?.x {
			xRange = from...max(to, currentTime)
		}
		else {
			xRange = currentTime...currentTime
		}
		let yRange = 0...(states.lazy.map{$0.y}.max() ?? 0)
		
		let row = NCExtractorDetailsRow(extractor: extractor, currentTime: currentTime)
		wasteState = row.wasteState
		yield = row.yield
		waste = row.waste

		super.init(prototype: Prototype.NCDefaultTableViewCell.default, facility: extractor)
		
		if extractor.output.typeID > 0 {
			self.children = [NCFacilityChartRow(data: states, xRange: xRange, yRange: yRange, currentTime: currentTime, expiryTime: extractor.expiryTime, identifier: extractor.identifier),
			                 NCFacilityOutputRow(typeID: extractor.output.typeID, identifier: extractor.identifier),
//			                 NCTypeInfoRow(typeID: extractor.output.typeID, accessoryType: .disclosureIndicator, route: Router.Database.TypeInfo(extractor.output.typeID)),
			                 row,
			                 DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty)
			]
		}
		
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
			extractor.engine?.performBlockAndWait {
				if self.extractor.output.typeID > 0 {
					if let state = self.wasteState {
						let t = state.timestamp - self.currentTime
						let p = Double(self.waste) / Double(self.waste + self.yield) * 100
						if t > 0 {
							cell.subtitleLabel?.text = String(format: NSLocalizedString("Waste in %@ (%.0f%%)", comment: ""), NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes), p)
						}
						else {
							cell.subtitleLabel?.text = String(format: NSLocalizedString("Waste %.0f%%", comment: ""), p)
						}
						cell.subtitleLabel?.textColor = .yellow
					}
					else {
						let t = self.extractor.expiryTime - self.currentTime
						if t > 0 {
							cell.subtitleLabel?.text = NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes)
						}
						else {
							cell.subtitleLabel?.text = NSLocalizedString("Finished", comment: "")
						}
						cell.subtitleLabel?.textColor = .lightText
					}
				}
				else {
					cell.subtitleLabel?.text = NSLocalizedString("Not Routed", comment: "")
					cell.subtitleLabel?.textColor = .lightText
				}
		}
	}
}

class NCFactoryRow: NCFacilityRow {

	init(factory: NCFittingIndustryFacility, currentTime: TimeInterval) {

		super.init(prototype: Prototype.NCDefaultTableViewCell.default, facility: factory)
		
		
		let states = factory.states as? [NCFittingProductionState]
		let lastState = states?.reversed().first {$0.currentCycle == nil}
		
		var ratio: [Int: Double] = [:]
		
		for input in factory.inputs {
			guard let commodity = input.commodity else {continue}
			guard let incomming = input.source?.incomming(with: commodity) else {continue}
			ratio[incomming.typeID] = (ratio[incomming.typeID] ?? 0) + Double(incomming.quantity)
		}
		
		let p = ratio.filter{$0.value > 0}.map{1.0 / $0.value}.max() ?? 1
		
		for (key, value) in ratio {
			ratio[key] = ((value * p) * 10).rounded() / 10
		}
		
		let expiryTime = lastState?.timestamp ?? Date.distantPast.timeIntervalSinceReferenceDate
		let identifier = factory.identifier
		let items = ratio.sorted(by: {$0.key < $1.key})
		let inputs = items.map {
			NCFactoryInputRow(typeID: $0.key, identifier: identifier, currentTime: currentTime, expiryTime: expiryTime)
		}
		
//		let title = rows.count > 1
//			? NSLocalizedString("Inputs", comment: "") + " (\(items.map{$0.value == 0 ? "0" : $0.value == 1 ? "1" :  String(format: "%.1f", $0.value)}.joined(separator: ":")))"
//			: NSLocalizedString("Input", comment: "")
		
		//			let section = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.default,
		//			                                 nodeIdentifier: "\(factory.identifier).inputs",
		//				title: title.uppercased(),
		//				children: rows)
		//			let section = DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, nodeIdentifier: "\(factory.identifier).inputs", title: title.uppercased())
		//			children.append(section)
		
		var children: [TreeNode] = [NCFactoryDetailsRow(factory: factory, inputRatio: items.map{$0.value}, currentTime: currentTime)]
		children.append(contentsOf: inputs as [TreeNode])
		
		if factory.output.typeID > 0 {
			//			let section = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.default,
			//			                                 nodeIdentifier: "\(factory.identifier).output",
			//				title: NSLocalizedString("Output", comment: "").uppercased(),
			//				children: [NCTypeInfoRow(typeID: factory.output.typeID, accessoryType: .disclosureIndicator, route: Router.Database.TypeInfo(factory.output.typeID))])
			//			let section = DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, nodeIdentifier: "\(factory.identifier).output", title: NSLocalizedString("Output", comment: "").uppercased())
			//			section.children = [NCTypeInfoRow(typeID: factory.output.typeID, accessoryType: .disclosureIndicator, route: Router.Database.TypeInfo(factory.output.typeID))]
			//			children.append(section)
			children.append(NCFacilityOutputRow(typeID: factory.output.typeID, identifier: factory.identifier))
		}

		if !children.isEmpty {
			children.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty))
		}
		self.children = children
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.subtitleLabel?.text = nil
	}
}

class NCFactoryInputRow: TreeRow {
	let typeID: Int
	let identifier: Int64
	let currentTime: TimeInterval
	let expiryTime: TimeInterval
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.typeID]
	}()
	
	init(typeID: Int, identifier: Int64, currentTime: TimeInterval, expiryTime: TimeInterval) {
		
		self.typeID = typeID
		self.identifier = identifier
		self.currentTime = currentTime
		self.expiryTime = expiryTime
		
		super.init(prototype: Prototype.NCDefaultTableViewCell.attribute, route: Router.Database.TypeInfo(typeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		
		cell.titleLabel?.text = NSLocalizedString("Input", comment: "").uppercased()
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		
		let typeName = type?.typeName ?? NSLocalizedString("Unknown", comment: "")

		let shortage = expiryTime - currentTime
		if shortage <= 0  {
			cell.subtitleLabel?.attributedText = typeName + " (\(NSLocalizedString("Depleted", comment: "")))" * [NSForegroundColorAttributeName: UIColor.red]
		}
		else {
			let s = String(format: NSLocalizedString("Shortage in %@", comment: ""), NCTimeIntervalFormatter.localizedString(from: shortage, precision: .minutes))
			cell.subtitleLabel?.attributedText = typeName + " (\(s))" * [NSForegroundColorAttributeName: UIColor.caption]
		}
		cell.accessoryType = .disclosureIndicator
	}
	
	override var hashValue: Int {
		return [identifier, typeID].hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFactoryInputRow)?.hashValue == hashValue
	}

}

class NCStorageRow: NCFacilityRow {
	let volume: Double
	let capacity: Double
	
	init(storage: NCFittingStorageFacility, currentTime: TimeInterval) {
		let capacity = storage.capacity
		
		var children: [TreeNode] = []
		
		if capacity > 0 {
			let states = storage.states
			var data = states.flatMap { state -> (BarChart.Item)? in
				let total = state.volume
				return BarChart.Item(x: state.timestamp, y: total, f: 1)
				}
			
			let xRange: ClosedRange<TimeInterval>
			if let from = data.first?.x, let to = data.last?.x {
				if to > currentTime {
					xRange = from...to
				}
				else {
					xRange = from...currentTime
					if var last = data.last {
						last.x = currentTime
						data.append(last)
					}
				}
			}
			else {
				xRange = currentTime...currentTime
			}
			let yRange = 0...capacity

			
			let current = states.reversed().first {$0.timestamp < currentTime} ?? states.last
			
			children.append(NCFacilityChartRow(data: data, xRange: xRange, yRange: yRange, currentTime: currentTime, expiryTime: xRange.upperBound, identifier: storage.identifier))
			
			volume = current?.volume ?? 0
			
			let commodities = current?.commodities.map {NCCommodityRow(commodity: $0, identifier: storage.identifier) }
			if let commodities = commodities, !commodities.isEmpty {
				children.append(contentsOf: commodities as [TreeNode])
			}
			
			
			
			children.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty))
			
			

		}
		else {
			volume = 0
		}
		self.capacity = capacity
		
		super.init(prototype: Prototype.NCDefaultTableViewCell.default, facility: storage)

		self.children = children
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		let p = capacity > 0 ? volume / capacity * 100 : 0
		
		cell.subtitleLabel?.text = "\(NCRangeFormatter(unit: .cubicMeter, style: .full).string(for: volume, maximum: capacity)) (\(NCUnitFormatter.localizedString(from: p, unit: .none, style: .full))%)"
		cell.subtitleLabel?.textColor =  p < 95 ? .lightText : .yellow
	}
}

class NCCommodityRow: TreeRow {
	let typeID: Int
	let identifier: Int64
	let quantity: Int
	let volume: Double
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.typeID]
	}()

	init(commodity: NCFittingCommodity, identifier: Int64) {
		
		self.typeID = commodity.typeID
		self.identifier = identifier
		quantity = commodity.quantity
		volume = commodity.volume
		super.init(prototype: Prototype.NCDefaultTableViewCell.default, route: Router.Database.TypeInfo(typeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.subtitleLabel?.text = "\(NCUnitFormatter.localizedString(from: quantity, unit: .none, style: .full)) (\(NCUnitFormatter.localizedString(from: volume, unit: .cubicMeter, style: .full)))"
		cell.subtitleLabel?.textColor = .lightText
		cell.accessoryType = .disclosureIndicator
	}
	
	override var hashValue: Int {
		return [identifier, typeID].hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCCommodityRow)?.hashValue == hashValue
	}

}

class NCPlanetaryViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		needsReloadOnAccountChange = true
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
							Prototype.NCDefaultTableViewCell.placeholder,
							Prototype.NCDefaultTableViewCell.attribute,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCFacilityChartTableViewCell.default,
		                    Prototype.NCExtractorDetailsTableViewCell.default,
		                    Prototype.NCFactoryDetailsTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.empty
		                    ])
		
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		dataManager.colonies { result in
			self.colonies = result
			completionHandler([result.cacheRecord].flatMap {$0})
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = colonies?.value {
			tableView.backgroundView = nil
			
			let progress = Progress(totalUnitCount: Int64(value.count))
			let engine = NCFittingEngine()
			var sections = [NCColonySection]()
			let dispatchGroup = DispatchGroup()
			
			for colony in value {
				progress.perform {
					dispatchGroup.enter()
					dataManager.colonyLayout(planetID: colony.planetID) { result in
						sections.append(NCColonySection(colony: colony, layout: result, engine: engine))
						dispatchGroup.leave()
					}
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				self.treeController?.content = RootNode(sections)
				completionHandler()
			}
			
		}
		else {
			tableView.backgroundView = treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: colonies?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}

	private var colonies: NCCachedResult<[ESI.PlanetaryInteraction.Colony]>?

	
}
