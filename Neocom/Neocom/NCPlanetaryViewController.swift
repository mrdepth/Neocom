//
//  NCPlanetaryViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import Dgmpp

enum NCColonyError: Error {
	case invalidLayout
}

class NCColonySection: TreeSection {
	let colony: ESI.PlanetaryInteraction.Colony
	let layout: NCResult<ESI.PlanetaryInteraction.ColonyLayout>
	var isHalted: Bool = false
	let planet = DGMPlanet()
	
	lazy var planetInfo: NCDBMapDenormalize? = {
		return NCDatabase.sharedDatabase?.mapDenormalize[self.colony.planetID]
	}()
	
	init(colony: ESI.PlanetaryInteraction.Colony, layout: NCResult<ESI.PlanetaryInteraction.ColonyLayout>) {
		self.colony = colony
		self.layout = layout
		
		super.init(prototype: Prototype.NCHeaderTableViewCell.default)
		
		switch layout {
		case let .success(layout):
//			let planetTypeID: Int32 = NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext in
//				return NCDBInvType.invTypes(managedObjectContext: managedObjectContext)[self.colony.planetID]?.typeID
//			} ?? 0
			
			do {
				
				
				for pin in layout.pins {
					guard planet[pin.pinID] == nil else {throw NCColonyError.invalidLayout}
					let facility = try planet.add(facility: pin.typeID, identifier: pin.pinID)
					
					switch facility {
					case let ecu as DGMExtractorControlUnit:
						ecu.launchTime = pin.lastCycleStart ?? Date.init(timeIntervalSinceReferenceDate: 0)
						ecu.installTime = pin.installTime ?? Date.init(timeIntervalSinceReferenceDate: 0)
						ecu.expiryTime = pin.expiryTime ?? Date.init(timeIntervalSinceReferenceDate: 0)
						ecu.cycleTime = TimeInterval(pin.extractorDetails?.cycleTime ?? 0)
						ecu.quantityPerCycle = pin.extractorDetails?.qtyPerCycle ?? 0
					//							ecu.quantityPerCycle *= 2
					case let factory as DGMFactory:
						factory.launchTime = pin.lastCycleStart ?? Date.init(timeIntervalSinceReferenceDate: 0)
						if let schematicID = pin.schematicID {
							factory.schematicID = schematicID
						}
						
					default:
						break
					}
					pin.contents?.filter {$0.amount > 0}.forEach {
						try? facility.add(DGMCommodity(typeID: $0.typeID, quantity: Int($0.amount)))
					}
				}
				
				for route in layout.routes {
					do {
						guard let source = planet[route.sourcePinID],
							let destination = planet[route.destinationPinID] else {throw NCColonyError.invalidLayout}
						let route = try DGMRoute(from: source, to: destination, commodity: DGMCommodity(typeID: route.contentTypeID, quantity: Int(route.quantity)))
						planet.add(route: route)
					}
					catch {
						
					}
				}
				
				let lastUpdate = colony.lastUpdate
				planet.lastUpdate = lastUpdate
				
				planet.run()
				
				let currentTime = Date()
				var rows = planet.facilities.flatMap { i -> NCFacilityRow? in
					switch i {
					case let facility as DGMExtractorControlUnit:
						return NCExtractorControlUnitRow(extractor: facility, currentTime: currentTime)
					case let facility as DGMFactory:
						return NCFactoryRow(factory: facility, currentTime: currentTime)
					case let facility as DGMStorage:
						return NCStorageRow(storage: facility, currentTime: currentTime)
					default:
						return nil
					}
				}
				
				rows.sort(by: {$0.sortDescriptor < $1.sortDescriptor})
				
				self.children = rows.map{DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [$0])}
				
				isHalted = planet.facilities.lazy.flatMap{$0 as? DGMExtractorControlUnit}.first {$0.expiryTime < currentTime} != nil
				isExpanded = isHalted
			}
			catch {
				self.children = [DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, title: error.localizedDescription)]
			}
		case let .failure(error):
			children = [DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, title: error.localizedDescription)]
		}

	}
	
	override var hashValue: Int {
		return colony.planetID.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCColonySection)?.hashValue == hashValue
	}
	
	lazy var title: NSAttributedString? = {
		let solarSystem = NCDatabase.sharedDatabase?.mapSolarSystems[self.colony.solarSystemID]
		let location = NCDatabase.sharedDatabase?.mapDenormalize[self.colony.planetID]?.itemName ?? solarSystem?.solarSystemName ?? NSLocalizedString("Unknown", comment: "")
		let title: NSAttributedString
		
		if let solarSystem = solarSystem {
			let security = solarSystem.security
			title = (String(format: "%.1f ", security) * [NSAttributedStringKey.foregroundColor: UIColor(security: security)] + location + " (\(self.colony.planetType.title))").uppercased()
		}
		else {
			title = (location + " (\(self.colony.planetType.title))").uppercased() * [:]
		}
		return self.isHalted ? title + " [\(NSLocalizedString("halted", comment: "").uppercased())]" * [NSAttributedStringKey.foregroundColor: UIColor.red] : title
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
	
	init(prototype: Prototype, facility: DGMFacility) {
		typeID = facility.typeID
		facilityName = facility.name
		identifier = facility.identifier
		let isExpanded: Bool
		switch facility {
		case is DGMExtractorControlUnit:
			sortDescriptor = "0\(facility.typeName ?? "")\(facilityName)"
			isExpanded = true
		case is DGMStorage:
			sortDescriptor = "1\(facility.typeName ?? "")\(facilityName)"
			isExpanded = false
		case is DGMFactory:
			sortDescriptor = "2\(facility.typeName ?? "")\(facilityName)"
			isExpanded = false
		default:
			sortDescriptor = "3\(facility.typeName ?? "")\(facilityName)"
			isExpanded = false
		}
		super.init(prototype: prototype, accessoryButtonRoute: Router.Database.TypeInfo(facility.typeID))
		isExpandable = true
		self.isExpanded = isExpanded
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.attributedText = (type?.typeName ?? "") + " \(facilityName)" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
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

	let wasteState: DGMProductionState?
	let currentTime: Date
	let yield: Int
	let waste: Int
	let extractor: DGMExtractorControlUnit
	
	init(extractor: DGMExtractorControlUnit, currentTime: Date) {
		self.currentTime = currentTime
		self.extractor = extractor
		
		let states = extractor.states.flatMap { state -> (BarChart.Item)? in
			guard let cycle = state.cycle else {return nil}
			let yield = Double(cycle.yield.quantity)
			let waste = Double(cycle.waste.quantity)
			let launchTime = state.timestamp

			let total = yield + waste
			let f = total > 0 ? yield / total : 1
			return BarChart.Item(x: launchTime.timeIntervalSinceReferenceDate, y: total, f: f)
		}
		
		let xRange: ClosedRange<Date>
		if let from = states.first?.x, let to = states.last?.x {
			xRange = Date(timeIntervalSinceReferenceDate: from)...max(Date(timeIntervalSinceReferenceDate: to), currentTime)
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
		
		if let output = extractor.output {
			self.children = [NCFacilityChartRow(data: states, xRange: xRange, yRange: yRange, currentTime: currentTime, expiryTime: extractor.expiryTime, identifier: extractor.identifier),
			                 NCFacilityOutputRow(typeID: output.typeID, identifier: extractor.identifier),
//			                 NCTypeInfoRow(typeID: extractor.output.typeID, accessoryType: .disclosureIndicator, route: Router.Database.TypeInfo(extractor.output.typeID)),
			                 row,
//			                 DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty)
			]
		}
		
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
//			extractor.engine?.performBlockAndWait {
				if extractor.output != nil {
					if let state = self.wasteState {
						let t = state.timestamp.timeIntervalSince(self.currentTime)
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
						let t = self.currentTime.timeIntervalSince(self.extractor.expiryTime)
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
//		}
	}
}

class NCFactoryRow: NCFacilityRow {

	init(factory: DGMFactory, currentTime: Date) {

		super.init(prototype: Prototype.NCDefaultTableViewCell.default, facility: factory)
		
		
		let states = factory.states
		let lastState = states.reversed().first {$0.cycle == nil}
		
		var ratio: [Int: Double] = [:]

		for input in factory.inputs {
			let commodity = input.commodity
			let income = input.from.income(typeID: commodity.typeID)
			guard income.quantity > 0 else {continue}
			ratio[income.typeID] = (ratio[income.typeID] ?? 0) + Double(income.quantity)
		}
		
		let p = ratio.filter{$0.value > 0}.map{1.0 / $0.value}.max() ?? 1
		
		for (key, value) in ratio {
			ratio[key] = ((value * p) * 10).rounded() / 10
		}
		
		let expiryTime = lastState?.timestamp ?? Date.distantPast
		let identifier = factory.identifier
		let items = ratio.sorted(by: {$0.key < $1.key})
		let inputs = items.map {
			NCFactoryInputRow(typeID: $0.key, identifier: identifier, currentTime: currentTime, expiryTime: expiryTime)
		}
		
		var children: [TreeNode] = []
		children.append(contentsOf: inputs as [TreeNode])
		
		if let output = factory.output {
			children.append(NCFacilityOutputRow(typeID: output.typeID, identifier: factory.identifier))
		}
		
		children.append(NCFactoryDetailsRow(factory: factory, inputRatio: items.map{$0.value}, currentTime: currentTime))

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
	let currentTime: Date
	let expiryTime: Date
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.typeID]
	}()
	
	init(typeID: Int, identifier: Int64, currentTime: Date, expiryTime: Date) {
		
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

		let shortage = expiryTime.timeIntervalSince(currentTime)
		if shortage <= 0  {
			cell.subtitleLabel?.attributedText = typeName + " (\(NSLocalizedString("Depleted", comment: "")))" * [NSAttributedStringKey.foregroundColor: UIColor.red]
		}
		else {
			let s = String(format: NSLocalizedString("Shortage in %@", comment: ""), NCTimeIntervalFormatter.localizedString(from: shortage, precision: .minutes))
			cell.subtitleLabel?.attributedText = typeName + " (\(s))" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
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
	
	init(storage: DGMStorage, currentTime: Date) {
		let capacity = storage.capacity
		
		var children: [TreeNode] = []
		
		if capacity > 0 {
			let states = storage.states
			var data = states.flatMap { state -> (BarChart.Item)? in
				let total = state.volume
				return BarChart.Item(x: state.timestamp.timeIntervalSinceReferenceDate, y: total, f: 1)
				}
			
			let xRange: ClosedRange<Date>
			if let from = data.first?.x, let to = data.last?.x {
				if Date(timeIntervalSinceReferenceDate: to) > currentTime {
					xRange = Date(timeIntervalSinceReferenceDate: from)...Date(timeIntervalSinceReferenceDate: to)
				}
				else {
					xRange = Date(timeIntervalSinceReferenceDate: from)...currentTime
					if var last = data.last {
						last.x = currentTime.timeIntervalSinceReferenceDate
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
			
			
			
//			children.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty))
			
			

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

	init(commodity: DGMCommodity, identifier: Int64) {
		
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
		accountChangeAction = .reload
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
			var sections = [NCColonySection]()
			let dispatchGroup = DispatchGroup()
			
			for colony in value {
				progress.perform {
					dispatchGroup.enter()
					dataManager.colonyLayout(planetID: colony.planetID) { result in
						let layout: NCResult<ESI.PlanetaryInteraction.ColonyLayout>
						
						switch result {
						case let .success(value, _):
							layout = .success(value)
						case let .failure(error):
							layout = .failure(error)
						}
						
//						engine.perform {
							sections.append(NCColonySection(colony: colony, layout: layout))
							dispatchGroup.leave()
//						}
					}
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				self.treeController?.content = RootNode(sections)
				self.tableView.backgroundView = self.treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: self.colonies?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
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
