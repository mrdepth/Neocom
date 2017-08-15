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
							factory.schematic = NCFittingSchematic(schematicID: pin.factoryDetails?.schematicID ?? 0)
						default:
							break
						}
					}
					
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
					
					rows.sort(by: {$0.priority == $1.priority ? $0.typeName < $1.typeName : $0.priority < $1.priority})
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
	let typeName: String
	let priority: Int
	let identifier: Int64
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.typeID]
	}()
	
	init(prototype: Prototype, facility: NCFittingFacility) {
		typeID = facility.typeID
		typeName = facility.typeName
		identifier = facility.identifier
		switch facility {
		case is NCFittingExtractorControlUnit:
			priority = 0
		case is NCFittingIndustryFacility:
			priority = 1
		case is NCFittingStorageFacility:
			priority = 2
		default:
			priority = 3
		}
		super.init(prototype: prototype)
		isExpandable = true
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
	}
	
	override var hashValue: Int {
		return identifier.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFacilityRow)?.hashValue == hashValue
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
			xRange = from...to
		}
		else {
			xRange = currentTime...currentTime
		}
		let yRange = 0...(states.lazy.map{$0.y}.max() ?? 0)
		
//		self.states = states
//		current = states.first {$0.x > currentTime}
//		waste = states.first {$0.f < 1 && $0.x > currentTime}
//		(totalYield, totalWaste) = states.reduce((0, 0)) {($0.0 + $1.y * $1.f, $0.1 + $1.y * (1 - $1.f))}

		let row = NCExtractorDetailsRow(extractor: extractor, currentTime: currentTime)
		wasteState = row.wasteState
		yield = row.yield
		waste = row.waste

		super.init(prototype: Prototype.NCDefaultTableViewCell.default, facility: extractor)
		
		if extractor.output.typeID > 0 {
			self.children = [NCFacilityChartRow(data: states, xRange: xRange, yRange: yRange, currentTime: currentTime, expiryTime: extractor.expiryTime, identifier: extractor.identifier),
			                 NCTypeInfoRow(typeID: extractor.output.typeID),
			                 row,
			                 DefaultTreeSection.init(prototype: Prototype.NCHeaderTableViewCell.empty)
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
	let extrapolatedProductionTime: TimeInterval?
	let extrapolatedIdleTime: TimeInterval?
	init(factory: NCFittingIndustryFacility, currentTime: TimeInterval) {
		let states = factory.states as? [NCFittingProductionState]
		let lastState = states?.reversed().first {$0.currentCycle == nil}
		let firstProductionState = states?.first {$0.currentCycle?.launchTime == $0.timestamp}
		let lastProductionState = states?.reversed().first {$0.currentCycle?.launchTime == $0.timestamp}
		let currentState = states?.first {$0.timestamp > currentTime}
		
		let extrapolatedEfficiency = lastState?.efficiency
		let duration: TimeInterval? = {
			guard let currentState = currentState, let firstProductionState = firstProductionState else {return nil}
			return currentState.timestamp - firstProductionState.timestamp
		}()
		let extrapolatedDuration: TimeInterval? = {
			guard let lastState = lastState, let firstProductionState = firstProductionState else {return nil}
			return lastState.timestamp - firstProductionState.timestamp
		}()
		let productionTime: TimeInterval? = {
			guard let currentState = currentState, let duration = duration else {return nil}
			return currentState.efficiency * duration
		}()
		(extrapolatedProductionTime, extrapolatedIdleTime) = {
			guard let lastState = lastState, let extrapolatedDuration = extrapolatedDuration else {return (nil, nil)}
			let extrapolatedProductionTime = lastState.efficiency * extrapolatedDuration
			let extrapolatedIdleTime = extrapolatedDuration - extrapolatedProductionTime
			return (extrapolatedProductionTime, extrapolatedIdleTime)
		}()

		super.init(prototype: Prototype.NCDefaultTableViewCell.default, facility: factory)
	}
}

class NCStorageRow: NCFacilityRow {
	init(storage: NCFittingStorageFacility, currentTime: TimeInterval) {
		let capacity = storage.capacity
		
		if capacity > 0 {
			let states = storage.states.flatMap { state -> (BarChart.Item)? in
				let total = state.volume / capacity
				return BarChart.Item(x: state.timestamp, y: total, f: 1)
				} ?? []
			
			let last = states.last
			let current = states.first {$0.x > currentTime} ?? last

		}
		
		super.init(prototype: Prototype.NCDefaultTableViewCell.default, facility: storage)

	}
}

class NCPlanetaryViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		needsReloadOnAccountChange = true
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCFacilityChartTableViewCell.default,
		                    Prototype.NCExtractorDetailsTableViewCell.default,
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
