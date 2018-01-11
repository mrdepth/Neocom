//
//  NCDatabaseTypeInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import EVEAPI

class NCDatabaseTypeInfoRow: DefaultTreeRow {
	
	convenience init?(attribute: NCDBDgmTypeAttribute, value: Float?) {
		func toString(_ value: Float, _ unit: String?) -> String {
			var s = NCUnitFormatter.localizedString(from: Double(value), unit: .none, style: .full)
			if let unit = unit {
				s += " " + unit
			}
			return s
		}
		guard let attributeType = attribute.attributeType else {return nil}
		
		let value = value ?? attribute.value
		
		var title: String?
		var subtitle: String?
		var image: UIImage?
		var object: Any?
		var route: Route?

		switch NCDBUnitID(rawValue: Int(attributeType.unit?.unitID ?? 0)) ?? NCDBUnitID.none {
		case .attributeID:
			guard let attributeType = NCDBDgmAttributeType.dgmAttributeTypes(managedObjectContext: attribute.managedObjectContext!)[Int(value)] else {break}
			subtitle = attributeType.displayName ?? attributeType.attributeName
			
		case .groupID:
			guard let group = NCDBInvGroup.invGroups(managedObjectContext: attribute.managedObjectContext!)[Int(value)] else {break}
			image = attributeType.icon?.image?.image ?? group.icon?.image?.image
			subtitle = group.groupName
			object = group.objectID
			route = Router.Database.Types(group: group)
		case .typeID:
			guard let type = NCDBInvType.invTypes(managedObjectContext: attribute.managedObjectContext!)[Int(value)] else {break}
			image = type.icon?.image?.image ?? attributeType.icon?.image?.image
			subtitle = type.typeName
			object = type.objectID
			route = Router.Database.TypeInfo(type.objectID)
		case .sizeClass:
			switch Int(value) {
			case 0:
				return nil;
			case 1:
				subtitle = NSLocalizedString("Small", comment: "")
			case 2:
				subtitle = NSLocalizedString("Medium", comment: "")
			case 3:
				subtitle = NSLocalizedString("Large", comment: "")
			case 4:
				subtitle = NSLocalizedString("X-Large", comment: "")
			default:
				subtitle = "\(Int(value))"
			}
		case .bonus:
			subtitle = "+" + NCUnitFormatter.localizedString(from: Double(value), unit: .none, style: .full)
			image = attributeType.icon?.image?.image
		case .boolean:
			subtitle = Int(value) == 0 ? NSLocalizedString("No", comment: "") : NSLocalizedString("Yes", comment: "")
		case .inverseAbsolutePercent, .inversedModifierPercent:
			subtitle = toString((1.0 - value) * 100.0, attributeType.unit?.displayName)
		case .modifierPercent:
			subtitle = toString((value - 1.0) * 100.0, attributeType.unit?.displayName)
		case .absolutePercent:
			subtitle = toString(value * 100.0, attributeType.unit?.displayName)
		case .milliseconds:
			subtitle = toString(value / 1000.0, attributeType.unit?.displayName)
		default:
			subtitle = toString(value, attributeType.unit?.displayName)
		}
		
		if title == nil {
			if let displayName = attributeType.displayName, !displayName.isEmpty {
				title = displayName
			}
			else if let attributeName = attributeType.attributeName, !attributeName.isEmpty {
				title = attributeName
			}
			else {
				return nil
			}
		}
		if image == nil {
			image = attributeType.icon?.image?.image
		}
		self.init(prototype: Prototype.NCDefaultTableViewCell.attribute,
		           nodeIdentifier: attribute.attributeType?.attributeName,
		           image: image,
		           title: title?.uppercased(),
		           subtitle: subtitle,
		           accessoryType: route != nil ? .disclosureIndicator : .none,
		           route: route,
		           object: object)
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.textColor = .caption
		cell.subtitleLabel?.textColor = .white
		cell.iconView?.tintColor = .white
	}
	
}

class NCDatabaseTypeSkillRow: DefaultTreeRow {
	var trainingTime: TimeInterval = 0
	var skill: NCTrainingSkill?
	
	init(skill: NCDBInvType, level: Int, character: NCCharacter, children: [TreeNode]?) {
		let title = NSAttributedString(skillName: skill.typeName!, level: level)
		let image: UIImage?
		let trainingSkill: NCTrainingSkill?
		let trainingTime: TimeInterval
		if let trainedSkill = character.skills[Int(skill.typeID)], let trainedLevel = trainedSkill.level {
			if trainedLevel >= level {
				image = #imageLiteral(resourceName: "skillRequirementMe")
				trainingTime = 0
				trainingSkill = nil
			}
			else {
				trainingSkill = NCTrainingSkill(type: skill, skill: trainedSkill, level: level)
				trainingTime = trainingSkill?.trainingTime(characterAttributes: character.attributes) ?? 0
				image = #imageLiteral(resourceName: "skillRequirementNotMe")
			}
		}
		else {
			trainingSkill = NCTrainingSkill(type: skill, level: level)
			trainingTime = trainingSkill?.trainingTime(characterAttributes: character.attributes) ?? 0
			image = #imageLiteral(resourceName: "skillRequirementNotInjected")
		}
		let subtitle = trainingTime > 0 ? NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
		super.init(prototype: Prototype.NCDefaultTableViewCell.default,
		          image: image,
		          attributedTitle: title,
		          subtitle: subtitle,
		          accessoryType: .disclosureIndicator,
		          route: Router.Database.TypeInfo(skill.objectID),
		          object: skill.objectID)
		self.children = children ?? []
		self.skill = trainingSkill
		self.trainingTime = trainingTime
	}
	
	convenience init(skill: NCDBInvTypeRequiredSkill, character: NCCharacter, children: [TreeNode]? = nil) {
		self.init(skill: skill.skillType!, level: Int(skill.skillLevel), character: character, children: children)
	}

	convenience init(skill: NCDBIndRequiredSkill, character: NCCharacter, children: [TreeNode]? = nil) {
		self.init(skill: skill.skillType!, level: Int(skill.skillLevel), character: character, children: children)
	}

	convenience init(skill: NCDBCertSkill, character: NCCharacter, children: [TreeNode]? = nil) {
		self.init(skill: skill.type!, level: Int(skill.skillLevel), character: character, children: children)
	}

	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.indentationWidth = 10
		let tintColor = trainingTime > 0 ? UIColor.lightText : UIColor.white
		cell.subtitleLabel?.textColor = tintColor
		cell.iconView?.tintColor = tintColor

		
		if let skill = self.skill/*, trainingTime > 0*/ {
			let typeID = skill.skill.typeID
			let level = skill.level

			let item = NCAccount.current?.activeSkillPlan?.skills?.first(where: { (skill) -> Bool in
				let skill = skill as! NCSkillPlanSkill
				return Int(skill.typeID) == typeID && Int(skill.level) >= level
			})
			if item != nil {
				cell.iconView?.image = #imageLiteral(resourceName: "skillRequirementQueued")
			}
		}
	}
	
}

class NCDatabaseTrainingSkillRow: NCDatabaseTypeSkillRow {
	let character: NCCharacter
	init(skill: NCDBInvType, level: Int, character: NCCharacter) {
		self.character = character
		super.init(skill: skill, level: level, character: character, children: nil)
		route = nil
		accessoryType = .none
	}
}

class NCDatabaseTypeMarketRow: TreeRow {
	var volume: UIBezierPath?
	var median: UIBezierPath?
	var donchian: UIBezierPath?
	var donchianVisibleRange: CGRect?
	var date: ClosedRange<Date>?
	let history: NCCacheRecord
	var observer: NCManagedObjectObserver?
	
	init(history: NCCacheRecord, typeID: Int) {
		self.history = history
		super.init(prototype: Prototype.NCMarketHistoryTableViewCell.default, route: Router.Database.MarketInfo(typeID))
		self.observer = NCManagedObjectObserver(managedObject: history)  {[weak self] (_, _) in
			self?.reload()
		}
		reload()
	}
	
	func reload() {
		NCCache.sharedCache?.performBackgroundTask { managedObjectContext in
			guard let record = (try? managedObjectContext.existingObject(with: self.history.objectID)) as? NCCacheRecord else {return}
			guard let history: [ESI.Market.History] = record.get() else {return}
			guard history.count > 0 else {return}
			guard let date = history.last?.date.addingTimeInterval(-3600 * 24 * 365) else {return}
			guard let i = history.index(where: {
				$0.date > date
			}) else {
				return
			}
			
			let range = history.suffix(from: i).indices
			
			let visibleRange = { () -> ClosedRange<Double> in
				var h2 = 0 as Double
				var h = 0 as Double
				var l2 = 0 as Double
				var l = 0 as Double
				let n = Double(range.count)
				for i in range {
					let item = history[i]
					h += Double(item.highest) / n
					h2 += Double(item.highest * item.highest) / n
					l += Double(item.lowest) / n
					l2 += Double(item.lowest * item.lowest) / n
				}
				let avgl = l
				let avgh = h
				h *= h
				l *= l
				let devh = h < h2 ? sqrt(h2 - h) : 0
				let devl = l < l2 ? sqrt(l2 - l) : 0
				return (avgl - devl * 3)...(avgh + devh * 3)
			}()

			
			let volume = UIBezierPath()
			volume.move(to: CGPoint(x: 0, y: 0))
			
			let donchian = UIBezierPath()
			let avg = UIBezierPath()
			
			var x: CGFloat = 0
			var isFirst = true
			
			var v = 0...0 as ClosedRange<Int64>
			var p = 0...0 as ClosedRange<Double>
			let d = history[range.first!].date...history[range.last!].date
			var prevT: TimeInterval?
			
			var lowest = Double.greatestFiniteMagnitude as Double
			var highest = 0 as Double
			
			for i in range {
				let item = history[i]
				if visibleRange.contains(Double(item.lowest)) {
					lowest = min(lowest, Double(item.lowest))
				}
				if visibleRange.contains(Double(item.highest)) {
					highest = max(highest, Double(item.highest))
				}
				
				let t = item.date.timeIntervalSinceReferenceDate
				x = CGFloat(item.date.timeIntervalSinceReferenceDate)
				let lowest = history[max(i - 4, 0)...i].min {
					$0.lowest < $1.lowest
					}!
				let highest = history[max(i - 4, 0)...i].max {
					$0.highest < $1.highest
					}!
				if isFirst {
					avg.move(to: CGPoint(x: x, y: CGFloat(item.average)))
					isFirst = false
				}
				else {
					avg.addLine(to: CGPoint(x: x, y: CGFloat(item.average)))
				}
				if let prevT = prevT {
					volume.append(UIBezierPath(rect: CGRect(x: CGFloat(prevT), y: 0, width: CGFloat(t - prevT), height: CGFloat(item.volume))))
					donchian.append(UIBezierPath(rect: CGRect(x: CGFloat(prevT), y: CGFloat(lowest.lowest), width: CGFloat(t - prevT), height: abs(CGFloat(highest.highest - lowest.lowest)))))
				}
				prevT = t
				
				v = min(v.lowerBound, item.volume)...max(v.upperBound, item.volume)
				p = min(p.lowerBound, Double(lowest.lowest))...max(p.upperBound, Double(highest.highest))
			}
			
			var donchianVisibleRange = donchian.bounds
			if lowest < highest {
				donchianVisibleRange.origin.y = CGFloat(lowest)
				donchianVisibleRange.size.height = CGFloat(highest - lowest)
			}
			
			DispatchQueue.main.async {
				self.volume = volume
				self.median = avg
				self.donchian = donchian
				self.donchianVisibleRange = donchianVisibleRange
				self.date = d
				self.treeController?.reloadCells(for: [self])
			}
		}
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCMarketHistoryTableViewCell else {return}
		cell.marketHistoryView.volume = volume
		cell.marketHistoryView.median = median
		cell.marketHistoryView.donchian = donchian
		cell.marketHistoryView.donchianVisibleRange = donchianVisibleRange
		cell.marketHistoryView.date = date
	}
}

class NCDatabaseTypeResistanceRow: TreeRow {
	var em: Float = 0
	var thermal: Float = 0
	var kinetic: Float = 0
	var explosive: Float = 0
	
	init() {
		super.init(prototype: Prototype.NCDamageTypeTableViewCell.compact)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDamageTypeTableViewCell else {return}
		cell.emLabel.progress = em
		cell.emLabel.text = "\(Int(em * 100))%"
		cell.thermalLabel.progress = thermal
		cell.thermalLabel.text = "\(Int(thermal * 100))%"
		cell.kineticLabel.progress = kinetic
		cell.kineticLabel.text = "\(Int(kinetic * 100))%"
		cell.explosiveLabel.progress = explosive
		cell.explosiveLabel.text = "\(Int(explosive * 100))%"
	}
}

class NCDatabaseTypeDamageRow: TreeRow {
	var em: Float = 0
	var thermal: Float = 0
	var kinetic: Float = 0
	var explosive: Float = 0
	
	init() {
		super.init(prototype: Prototype.NCDamageTypeTableViewCell.compact)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCDamageTypeTableViewCell
		var total = em + thermal + kinetic + explosive
		if total == 0 {
			total = 1
		}
		
		cell.emLabel.progress = em / total
		cell.emLabel.text = NCUnitFormatter.localizedString(from: em, unit: .none, style: .short)
		cell.thermalLabel.progress = thermal / total
		cell.thermalLabel.text = NCUnitFormatter.localizedString(from: thermal, unit: .none, style: .short)
		cell.kineticLabel.progress = kinetic / total
		cell.kineticLabel.text = NCUnitFormatter.localizedString(from: kinetic, unit: .none, style: .short)
		cell.explosiveLabel.progress = explosive / total
		cell.explosiveLabel.text = NCUnitFormatter.localizedString(from: explosive, unit: .none, style: .short)
	}
}

class NCDatabaseSkillsSection: NCActionTreeSection {
	let trainingQueue: NCTrainingQueue
	let character: NCCharacter
	let trainingTime: TimeInterval
	
	init(nodeIdentifier: String?, title: String?, trainingQueue: NCTrainingQueue, character: NCCharacter, children: [TreeNode]? = nil) {
		self.trainingQueue = trainingQueue
		self.character = character
		trainingTime = trainingQueue.trainingTime(characterAttributes: character.attributes)
		let attributedTitle = NSMutableAttributedString(string: title ?? "")
		if trainingTime > 0 {
			attributedTitle.append(NSAttributedString(
				string: " (\(NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds)))",
				attributes: [NSAttributedStringKey.foregroundColor: UIColor.white]))
		}
		super.init(nodeIdentifier: nodeIdentifier,
		           attributedTitle: attributedTitle, children: children)
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCActionHeaderTableViewCell else {return}
		cell.button?.isHidden = NCAccount.current == nil || trainingTime == 0
	}
}

struct NCDatabaseTypeInfo {
	
	static func typeInfo(type: NCDBInvType, attributeValues: [Int: Float]?, completionHandler: @escaping ([TreeNode]) -> Void) {

		var marketSection: DefaultTreeSection?
		if type.marketGroup != nil {
			let regionID = (UserDefaults.standard.value(forKey: UserDefaults.Key.NCMarketRegion) as? Int) ?? NCDBRegionID.theForge.rawValue
			let typeID = Int(type.typeID)
			marketSection = DefaultTreeSection(nodeIdentifier: "Market", title: NSLocalizedString("Market", comment: "").uppercased(), children: [])
			
			let dataManager = NCDataManager(account: NCAccount.current)
			
			dataManager.marketHistory(typeID: typeID, regionID: regionID) { result in
				switch result {
				case let .success(value, cacheRecord):
					if let cacheRecord = cacheRecord, !value.isEmpty {
						let row = NCDatabaseTypeMarketRow(history: cacheRecord, typeID: typeID)
						marketSection?.children.append(row)
					}
				default:
					break
				}
			}
			
			dataManager.prices(typeIDs: [typeID]) { result in
				guard let price = result[typeID] else {return}
				let subtitle = NCUnitFormatter.localizedString(from: price, unit: .isk, style: .full)
				let row = NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute, image: #imageLiteral(resourceName: "wallet"), title: NSLocalizedString("PRICE", comment: ""), subtitle: subtitle, accessoryType: .disclosureIndicator, route: Router.Database.MarketInfo(typeID))
				marketSection?.children.insert(row, at: 0)
			}
		}
		switch NCDBCategoryID(rawValue: Int(type.group?.category?.categoryID ?? 0)) {
		case .blueprint?:
			blueprintInfo(type: type) { result in
				var sections = result
				if let marketSection = marketSection {
					sections.insert(marketSection, at: 0)
				}
				completionHandler(sections)
			}
		case .entity?:
			npcInfo(type: type) { result in
				completionHandler(result)
			}
		default:
			if type.wormhole != nil {
				whInfo(type: type) { result in
					completionHandler(result)
				}
			}
			else {
				itemInfo(type: type, attributeValues: attributeValues) { result in
					var sections = result
					if let marketSection = marketSection {
						sections.insert(marketSection, at: 0)
					}
					completionHandler(sections)
				}
			}
		}

	}
	
	static func itemInfo(type: NCDBInvType, attributeValues: [Int: Float]?, completionHandler: @escaping ([TreeSection]) -> Void) {
		
		NCCharacter.load(account: NCAccount.current) { result in
			let character: NCCharacter
			switch result {
			case let .success(value):
				character = value
			default:
				character = NCCharacter()
			}

			NCDatabase.sharedDatabase?.performBackgroundTask({ (managedObjectContext) in
				var sections = [TreeSection]()
				
				defer {
					DispatchQueue.main.async {
						completionHandler(sections)
					}
				}
				
				guard let type = (try? managedObjectContext.existingObject(with: type.objectID)) as? NCDBInvType else {return}
				
				if let skillPlan = NCDatabaseTypeInfo.skillPlan(type: type, character: character) {
					sections.append(skillPlan)
				}
				
				if let mastery = NCDatabaseTypeInfo.masteries(type: type, character: character) {
					sections.append(mastery)
				}
				
				if type.parentType != nil || (type.variations?.count ?? 0) > 0 {
					let n = max(type.variations?.count ?? 0, type.parentType?.variations?.count ?? 0) + 1
					let row = NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
					                                nodeIdentifier: "Variations",
					                                title: String(format: NSLocalizedString("%d types", comment: ""), n).uppercased(),
					                                accessoryType: .disclosureIndicator,
					                                route: Router.Database.Variations(typeObjectID: type.objectID))
					let section = DefaultTreeSection(nodeIdentifier: "VariationsSection", title: NSLocalizedString("Variations", comment: "").uppercased(), children: [row])
					sections.append(section)
				}
				else if (type.requiredForSkill?.count ?? 0) > 0 {
					let n = type.requiredForSkill!.count
					
					let row = NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
					                                nodeIdentifier: "RequiredFor",
					                                title: String(format: NSLocalizedString("%d types", comment: ""), n).uppercased(),
					                                accessoryType: .disclosureIndicator,
					                                route: Router.Database.RequiredFor(typeObjectID: type.objectID))
					let section = DefaultTreeSection(nodeIdentifier: "RequiredForSection", title: NSLocalizedString("Required for", comment: "").uppercased(), children: [row])
					sections.append(section)
				}
				
				let request = NSFetchRequest<NCDBDgmTypeAttribute>(entityName: "DgmTypeAttribute")
				request.predicate = NSPredicate(format: "type == %@ AND attributeType.published == TRUE", type)
				request.sortDescriptors = [NSSortDescriptor(key: "attributeType.attributeCategory.categoryID", ascending: true), NSSortDescriptor(key: "attributeType.attributeID", ascending: true)]
				let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "attributeType.attributeCategory.categoryID", cacheName: nil)
				guard let _ = try? results.performFetch() else {return}
				guard results.sections != nil else {return}
				
				for section in results.sections! {
					guard let attributeCategory = (section.objects?.first as? NCDBDgmTypeAttribute)?.attributeType?.attributeCategory else {continue}
					
					if attributeCategory.categoryID == Int32(NCDBAttributeCategoryID.requiredSkills.rawValue) {
						if let section = requiredSkills(type: type, character: character) {
							sections.append(section)
						}
						
					}
					else {
						let sectionTitle: String
						if Int(attributeCategory.categoryID) == NCDBAttributeCategoryID.null.rawValue {
							sectionTitle = NSLocalizedString("Other", comment: "")
						}
						else {
							sectionTitle = attributeCategory.categoryName ?? NSLocalizedString("Other", comment: "")
						}
						
						var rows = [TreeNode]()
						
						var resistanceRow: NCDatabaseTypeResistanceRow?
						
						func resistance() -> NCDatabaseTypeResistanceRow? {
							if resistanceRow == nil {
								resistanceRow = NCDatabaseTypeResistanceRow()
							}
							return resistanceRow
						}
						
						var damageRow: NCDatabaseTypeDamageRow?
						
						func damage() -> NCDatabaseTypeDamageRow? {
							if damageRow == nil {
								damageRow = NCDatabaseTypeDamageRow()
							}
							return damageRow
						}
						
						
						
						for attribute in (section.objects as? [NCDBDgmTypeAttribute]) ?? [] {
							let value = attributeValues?[Int(attribute.attributeType!.attributeID)] ?? attribute.value
							switch NCDBAttributeID(rawValue: Int(attribute.attributeType!.attributeID)) ?? NCDBAttributeID.none {
							case .emDamageResonance, .armorEmDamageResonance, .shieldEmDamageResonance,
							     .hullEmDamageResonance, .passiveArmorEmDamageResonance, .passiveShieldEmDamageResonance:
								guard let row = resistance() else {continue}
								row.em = max(row.em, 1 - value)
							case .thermalDamageResonance, .armorThermalDamageResonance, .shieldThermalDamageResonance,
							     .hullThermalDamageResonance, .passiveArmorThermalDamageResonance, .passiveShieldThermalDamageResonance:
								guard let row = resistance() else {continue}
								row.thermal = max(row.thermal, 1 - value)
							case .kineticDamageResonance, .armorKineticDamageResonance, .shieldKineticDamageResonance,
							     .hullKineticDamageResonance, .passiveArmorKineticDamageResonance, .passiveShieldKineticDamageResonance:
								guard let row = resistance() else {continue}
								row.kinetic = max(row.kinetic, 1 - value)
							case .explosiveDamageResonance, .armorExplosiveDamageResonance, .shieldExplosiveDamageResonance,
							     .hullExplosiveDamageResonance, .passiveArmorExplosiveDamageResonance, .passiveShieldExplosiveDamageResonance:
								guard let row = resistance() else {continue}
								row.explosive = max(row.explosive, 1 - value)
							case .emDamage:
								damage()?.em = value
							case .thermalDamage:
								damage()?.thermal = value
							case .kineticDamage:
								damage()?.kinetic = value
							case .explosiveDamage:
								damage()?.explosive = value

							case .warpSpeedMultiplier:
								guard let attributeType = attribute.attributeType else {continue}
								let baseWarpSpeed =  attributeValues?[NCDBAttributeID.baseWarpSpeed.rawValue] ?? type.allAttributes[NCDBAttributeID.baseWarpSpeed.rawValue]?.value ?? 1.0
								var s = NCUnitFormatter.localizedString(from: Double(value * baseWarpSpeed), unit: .none, style: .full)
								s += " " + NSLocalizedString("AU/sec", comment: "")
								rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
								                                  image: attributeType.icon?.image?.image,
								                                  title: NSLocalizedString("Warp Speed", comment: ""),
								                                  subtitle: s))
							default:
								guard let row = NCDatabaseTypeInfoRow(attribute: attribute, value: value) else {continue}
								rows.append(row)
							}
						}
						
						if let resistanceRow = resistanceRow {
							rows.append(resistanceRow)
							
						}
						if let damageRow = damageRow {
							rows.append(damageRow)
						}
						if rows.count > 0 {
							sections.append(DefaultTreeSection(nodeIdentifier: String(attributeCategory.categoryID), title: sectionTitle.uppercased(), children: rows))
						}
					}
				}
			})

		}
	}

	static func blueprintInfo(type: NCDBInvType, completionHandler: @escaping ([TreeSection]) -> Void) {
		
		NCCharacter.load(account: NCAccount.current) { result in
			let character: NCCharacter
			switch result {
			case let .success(value):
				character = value
			default:
				character = NCCharacter()
			}

			NCDatabase.sharedDatabase?.performBackgroundTask({ (managedObjectContext) in
				var sections = [TreeSection]()
				
				defer {
					DispatchQueue.main.async {
						completionHandler(sections)
					}
				}
				
				guard let type = (try? managedObjectContext.existingObject(with: type.objectID)) as? NCDBInvType else {return}
				guard let blueprintType = type.blueprintType else {return}
				for activity in blueprintType.activities?.sortedArray(using: [NSSortDescriptor(key: "activity.activityID", ascending: true)]) as? [NCDBIndActivity] ?? [] {
					var rows = [TreeNode]()
					let row = NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.default,
					                                image: #imageLiteral(resourceName: "skillRequirementQueued"),
//					                                title: NSLocalizedString("TIME", comment: ""),
					                                subtitle: NCTimeIntervalFormatter.localizedString(from: TimeInterval(activity.time), precision: .seconds))
					rows.append(row)
					
					for product in activity.products?.sortedArray(using: [NSSortDescriptor(key: "productType.typeName", ascending: true)]) as? [NCDBIndProduct] ?? [] {
						guard let type = product.productType, let subtitle = type.typeName else {continue}
						let title = NSLocalizedString("PRODUCT", comment: "")
						let image = type.icon?.image?.image
						let row = NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                                image: image,
						                                title: title,
						                                subtitle: subtitle,
						                                accessoryType: .disclosureIndicator,
						                                route: Router.Database.TypeInfo(type.objectID))
						rows.append(row)
					}
					
					var materials = [TreeNode]()
					for material in activity.requiredMaterials?.sortedArray(using: [NSSortDescriptor(key: "materialType.typeName", ascending: true)]) as? [NCDBIndRequiredMaterial] ?? [] {
						guard let type = material.materialType, let title = type.typeName else {continue}
						let subtitle = NCUnitFormatter.localizedString(from: material.quantity, unit: .none, style: .full)
						let image = type.icon?.image?.image
						
						let row = NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                                image: image,
						                                title: title,
						                                subtitle: subtitle,
						                                accessoryType: .disclosureIndicator,
						                                route: Router.Database.TypeInfo(type.objectID))
						materials.append(row)
					}
					if materials.count > 0 {
						rows.append(DefaultTreeSection(nodeIdentifier: "Materials\(activity.activity?.activityID ?? 0)", title: NSLocalizedString("MATERIALS", comment: ""), children: materials))
					}
					
					if let skills = requiredSkills(activity: activity, character: character) {
						rows.append(skills)
					}
					
					sections.append(DefaultTreeSection(nodeIdentifier: activity.activity?.activityName, title: activity.activity?.activityName?.uppercased(), children: rows))
				}
				
			})
			
		}
	}
	
	static func npcInfo(type: NCDBInvType, completionHandler: @escaping ([TreeSection]) -> Void) {
		
		NCDatabase.sharedDatabase?.performBackgroundTask({ (managedObjectContext) in
			var sections = [TreeSection]()
			
			defer {
				DispatchQueue.main.async {
					completionHandler(sections)
				}
			}
			
			guard let type = (try? managedObjectContext.existingObject(with: type.objectID)) as? NCDBInvType else {return}
			
			let request = NSFetchRequest<NCDBDgmTypeAttribute>(entityName: "DgmTypeAttribute")
			request.predicate = NSPredicate(format: "type == %@ AND attributeType.published == TRUE", type)
			request.sortDescriptors = [NSSortDescriptor(key: "attributeType.attributeCategory.categoryID", ascending: true), NSSortDescriptor(key: "attributeType.attributeID", ascending: true)]
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "attributeType.attributeCategory.categoryID", cacheName: nil)
			guard let _ = try? results.performFetch() else {return}
			guard results.sections != nil else {return}
			
			let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
			let attributes = type.allAttributes
			
			for section in results.sections! {
				guard let attributeCategory = (section.objects?.first as? NCDBDgmTypeAttribute)?.attributeType?.attributeCategory else {continue}

				let sectionTitle: String
				if Int(attributeCategory.categoryID) == NCDBAttributeCategoryID.null.rawValue {
					sectionTitle = NSLocalizedString("Other", comment: "")
				}
				else {
					sectionTitle = attributeCategory.categoryName ?? NSLocalizedString("Other", comment: "")
				}
				var rows = [TreeNode]()


				let category = NCDBAttributeCategoryID(rawValue: Int(attributeCategory.categoryID))
				switch category {
				case .turrets?:
					if let speed = attributes[NCDBAttributeID.speed.rawValue] {
						let damageMultiplier = attributes[NCDBAttributeID.damageMultiplier.rawValue]?.value ?? 1
						let maxRange = attributes[NCDBAttributeID.maxRange.rawValue]?.value ?? 0
						let falloff = attributes[NCDBAttributeID.falloff.rawValue]?.value ?? 0
						let trackingSpeed = attributes[NCDBAttributeID.trackingSpeed.rawValue]?.value ?? 0
						let duration = speed.value / 1000
						
						let em = attributes[NCDBAttributeID.emDamage.rawValue]?.value ?? 0
						let explosive = attributes[NCDBAttributeID.explosiveDamage.rawValue]?.value ?? 0
						let kinetic = attributes[NCDBAttributeID.kineticDamage.rawValue]?.value ?? 0
						let thermal = attributes[NCDBAttributeID.thermalDamage.rawValue]?.value ?? 0
						let total = (em + explosive + kinetic + thermal) * damageMultiplier
						
						let interval = duration > 0 ? duration : 1
						let dps = total / interval
						
						let damageRow = NCDatabaseTypeDamageRow()
						damageRow.em = em * damageMultiplier
						damageRow.explosive = explosive * damageMultiplier
						damageRow.kinetic = kinetic * damageMultiplier
						damageRow.thermal = thermal * damageMultiplier
						rows.append(damageRow)

						rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                                  nodeIdentifier: "TurretDamage",
						                                  image: #imageLiteral(resourceName: "turrets"),
						                                  title: NSLocalizedString("Damage per Second", comment: "").uppercased(),
						                                  subtitle: NCUnitFormatter.localizedString(from: dps, unit: .none, style: .full)))
						
						rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                                  nodeIdentifier: "TurretRoF",
						                                  image: #imageLiteral(resourceName: "rateOfFire"),
						                                  title: NSLocalizedString("Rate of Fire", comment: "").uppercased(),
						                                  subtitle: NCTimeIntervalFormatter.localizedString(from: TimeInterval(duration), precision: .seconds)))

						rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                                  nodeIdentifier: "TurretOptimal",
						                                  image: #imageLiteral(resourceName: "targetingRange"),
						                                  title: NSLocalizedString("Optimal Range", comment: "").uppercased(),
						                                  subtitle: NCUnitFormatter.localizedString(from: maxRange, unit: .meter, style: .full)))

						rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                                  nodeIdentifier: "TurretFalloff",
						                                  image: #imageLiteral(resourceName: "falloff"),
						                                  title: NSLocalizedString("Falloff", comment: "").uppercased(),
						                                  subtitle: NCUnitFormatter.localizedString(from: falloff, unit: .meter, style: .full)))


					}
				case .missile?:
					
					if let attribute = attributes[NCDBAttributeID.entityMissileTypeID.rawValue],
						let missile = invTypes[Int(attribute.value)] {
							rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                                   nodeIdentifier: attribute.attributeType?.attributeName,
						                                   image: missile.icon?.image?.image,
						                                   title: NSLocalizedString("Missile", comment: "").uppercased(),
						                                   subtitle: missile.typeName,
						                                   accessoryType: .disclosureIndicator,
						                                   route: Router.Database.TypeInfo(missile.objectID),
						                                   object: attribute))

						let duration = (attributes[NCDBAttributeID.missileLaunchDuration.rawValue]?.value ?? 1000) / 1000
						let damageMultiplier = attributes[NCDBAttributeID.missileDamageMultiplier.rawValue]?.value ?? 1
						let velocityMultiplier = attributes[NCDBAttributeID.missileEntityVelocityMultiplier.rawValue]?.value ?? 1
						let flightTimeMultiplier = attributes[NCDBAttributeID.missileEntityFlightTimeMultiplier.rawValue]?.value ?? 1
						
						let missileAttributes = missile.allAttributes
						
						let em = missileAttributes[NCDBAttributeID.emDamage.rawValue]?.value ?? 0
						let explosive = missileAttributes[NCDBAttributeID.explosiveDamage.rawValue]?.value ?? 0
						let kinetic = missileAttributes[NCDBAttributeID.kineticDamage.rawValue]?.value ?? 0
						let thermal = missileAttributes[NCDBAttributeID.thermalDamage.rawValue]?.value ?? 0
						let total = (em + explosive + kinetic + thermal) * damageMultiplier
						
						let damageRow = NCDatabaseTypeDamageRow()
						damageRow.em = em * damageMultiplier
						damageRow.explosive = explosive * damageMultiplier
						damageRow.kinetic = kinetic * damageMultiplier
						damageRow.thermal = thermal * damageMultiplier
						rows.append(damageRow)
						
						
						let velocity = (missileAttributes[NCDBAttributeID.maxVelocity.rawValue]?.value ?? 0) * velocityMultiplier
						let flightTime = (missileAttributes[NCDBAttributeID.explosionDelay.rawValue]?.value ?? 1) * flightTimeMultiplier / 1000
						let agility = missileAttributes[NCDBAttributeID.agility.rawValue]?.value ?? 0
						let mass = missile.mass

						let accelTime = min(flightTime, mass * agility / 1000000.0)
						let duringAcceleration = velocity / 2 * accelTime
						let fullSpeed = velocity * (flightTime - accelTime)
						let optimal = duringAcceleration + fullSpeed;
						
						let interval = duration > 0 ? duration : 1
						let dps = total / interval
						
						rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                                  nodeIdentifier: "MissileDamage",
						                                  image: #imageLiteral(resourceName: "launchers"),
						                                  title: NSLocalizedString("Damage per Second", comment: "").uppercased(),
						                                  subtitle: NCUnitFormatter.localizedString(from: dps, unit: .none, style: .full)))

						rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                                  nodeIdentifier: "MissileRoF",
						                                  image: #imageLiteral(resourceName: "rateOfFire"),
						                                  title: NSLocalizedString("Rate of Fire", comment: "").uppercased(),
						                                  subtitle: NCTimeIntervalFormatter.localizedString(from: TimeInterval(duration), precision: .seconds)))

						rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                                  nodeIdentifier: "MissileOptimal",
						                                  image: #imageLiteral(resourceName: "targetingRange"),
						                                  title: NSLocalizedString("Optimal Range", comment: "").uppercased(),
						                                  subtitle: NCUnitFormatter.localizedString(from: optimal, unit: .meter, style: .full)))




					}
				default:
					var resistanceRow: NCDatabaseTypeResistanceRow?
					
					func resistance() -> NCDatabaseTypeResistanceRow? {
						if resistanceRow == nil {
							resistanceRow = NCDatabaseTypeResistanceRow()
						}
						return resistanceRow
					}
					
					for attribute in (section.objects as? [NCDBDgmTypeAttribute]) ?? [] {
						switch NCDBAttributeID(rawValue: Int(attribute.attributeType!.attributeID)) ?? NCDBAttributeID.none {
						case .emDamageResonance, .armorEmDamageResonance, .shieldEmDamageResonance,
						     .hullEmDamageResonance, .passiveArmorEmDamageResonance, .passiveShieldEmDamageResonance:
							guard let row = resistance() else {continue}
							row.em = max(row.em, 1 - attribute.value)
						case .thermalDamageResonance, .armorThermalDamageResonance, .shieldThermalDamageResonance,
						     .hullThermalDamageResonance, .passiveArmorThermalDamageResonance, .passiveShieldThermalDamageResonance:
							guard let row = resistance() else {continue}
							row.thermal = max(row.thermal, 1 - attribute.value)
						case .kineticDamageResonance, .armorKineticDamageResonance, .shieldKineticDamageResonance,
						     .hullKineticDamageResonance, .passiveArmorKineticDamageResonance, .passiveShieldKineticDamageResonance:
							guard let row = resistance() else {continue}
							row.kinetic = max(row.kinetic, 1 - attribute.value)
						case .explosiveDamageResonance, .armorExplosiveDamageResonance, .shieldExplosiveDamageResonance,
						     .hullExplosiveDamageResonance, .passiveArmorExplosiveDamageResonance, .passiveShieldExplosiveDamageResonance:
							guard let row = resistance() else {continue}
							row.explosive = max(row.explosive, 1 - attribute.value)
						default:
							guard let row = NCDatabaseTypeInfoRow(attribute: attribute, value: nil) else {continue}
							rows.append(row)
						}
					}
					
					if let resistanceRow = resistanceRow {
						rows.append(resistanceRow)
					}
					
					if category == .shield {
						if let capacity = attributes[NCDBAttributeID.shieldCapacity.rawValue]?.value,
							let rechargeRate = attributes[NCDBAttributeID.shieldRechargeRate.rawValue]?.value,
							rechargeRate > 0 && capacity > 0 {
							let passive = 10.0 / (rechargeRate / 1000.0) * 0.5 * (1 - 0.5) * capacity
							
							rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
							                                  nodeIdentifier: "ShieldRecharge",
							                                  image: #imageLiteral(resourceName: "shieldRecharge"),
							                                  title: NSLocalizedString("Passive Recharge Rate", comment: "").uppercased(),
							                                  subtitle: NCUnitFormatter.localizedString(from: passive, unit: .hpPerSecond, style: .full)))

						}
						
						if let amount = attributes[NCDBAttributeID.entityShieldBoostAmount.rawValue]?.value,
							let duration = attributes[NCDBAttributeID.entityShieldBoostDuration.rawValue]?.value,
							duration > 0 && amount > 0 {
							let chance = (attributes[NCDBAttributeID.entityShieldBoostDelayChance.rawValue] ??
								attributes[NCDBAttributeID.entityShieldBoostDelayChanceSmall.rawValue] ??
								attributes[NCDBAttributeID.entityShieldBoostDelayChanceMedium.rawValue] ??
								attributes[NCDBAttributeID.entityShieldBoostDelayChanceLarge.rawValue])?.value ?? 0
							
							let repair = amount / (duration * (1 + chance) / 1000.0)
							
							rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
							                                  nodeIdentifier: "ShieldBooster",
							                                  image: #imageLiteral(resourceName: "shieldBooster"),
							                                  title: NSLocalizedString("Repair Rate", comment: "").uppercased(),
							                                  subtitle: NCUnitFormatter.localizedString(from: repair, unit: .hpPerSecond, style: .full)))

						}
					}
					else if category == .armor {
						if let amount = attributes[NCDBAttributeID.entityArmorRepairAmount.rawValue]?.value,
							let duration = attributes[NCDBAttributeID.entityArmorRepairDuration.rawValue]?.value,
							duration > 0 && amount > 0 {
							let chance = (attributes[NCDBAttributeID.entityArmorRepairDelayChance.rawValue] ??
								attributes[NCDBAttributeID.entityArmorRepairDelayChanceSmall.rawValue] ??
								attributes[NCDBAttributeID.entityArmorRepairDelayChanceMedium.rawValue] ??
								attributes[NCDBAttributeID.entityArmorRepairDelayChanceLarge.rawValue])?.value ?? 0
							
							let repair = amount / (duration * (1 + chance) / 1000.0)
							
							rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
							                                  nodeIdentifier: "ArmorRepair",
							                                  image: #imageLiteral(resourceName: "armorRepairer"),
							                                  title: NSLocalizedString("Repair Rate", comment: "").uppercased(),
							                                  subtitle: NCUnitFormatter.localizedString(from: repair, unit: .hpPerSecond, style: .full)))
							
						}
					}
					
				}
				
				
				
				if rows.count > 0 {
					if category == .entityRewards {
						sections.insert(DefaultTreeSection(nodeIdentifier: String(attributeCategory.categoryID), title: sectionTitle.uppercased(), children: rows), at: 0)
					}
					else {
						sections.append(DefaultTreeSection(nodeIdentifier: String(attributeCategory.categoryID), title: sectionTitle.uppercased(), children: rows))
					}
				}
			}
		})
	}
	
	static func whInfo(type: NCDBInvType, completionHandler: @escaping ([TreeNode]) -> Void) {
		NCDatabase.sharedDatabase?.performBackgroundTask({ (managedObjectContext) in
			var rows = [TreeNode]()
			
			defer {
				DispatchQueue.main.async {
					completionHandler(rows)
				}
			}
			
			guard let type = (try? managedObjectContext.existingObject(with: type.objectID)) as? NCDBInvType else {return}
			guard let wh = type.wormhole else {return}
			
			
			let eveIcons = NCDBEveIcon.eveIcons(managedObjectContext: managedObjectContext)
			
			if wh.targetSystemClass >= 0 {
				rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
				                                  nodeIdentifier: "LeadsInto",
				                                  image: #imageLiteral(resourceName: "systems"),
				                                  title: NSLocalizedString("Leads Into", comment: "").uppercased(),
				                                  subtitle: wh.targetSystemClassDisplayName))

			}
			if wh.maxStableTime > 0 {
				rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
				                                  nodeIdentifier: "MaximumStableTime",
				                                  image: eveIcons["22_16"]?.image?.image,
				                                  title: NSLocalizedString("Maximum Stable Time", comment: "").uppercased(),
				                                  subtitle: NCTimeIntervalFormatter.localizedString(from: TimeInterval(wh.maxStableTime) * 60, precision: .hours)))
				
			}
			if wh.maxStableMass > 0 {
				rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
				                                  nodeIdentifier: "MaximumStableMass",
				                                  image: eveIcons["02_10"]?.image?.image,
				                                  title: NSLocalizedString("Maximum Stable Mass", comment: "").uppercased(),
				                                  subtitle: NCUnitFormatter.localizedString(from: wh.maxStableMass, unit: .kilogram, style: .full)))
				
			}
			if wh.maxJumpMass > 0 {
				let row = NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
				                                nodeIdentifier: "MaximumJumpMass",
				                                image: eveIcons["36_13"]?.image?.image,
				                                title: NSLocalizedString("Maximum Jump Mass", comment: "").uppercased(),
				                                subtitle: NCUnitFormatter.localizedString(from: wh.maxJumpMass, unit: .kilogram, style: .full))
				let request = NSFetchRequest<NSDictionary>(entityName: "InvType")
				request.predicate = NSPredicate(format: "mass <= %f AND group.category.categoryID = 6 AND published = TRUE", wh.maxJumpMass)
				request.sortDescriptors = [
					NSSortDescriptor(key: "group.groupName", ascending: true),
					NSSortDescriptor(key: "typeName", ascending: true)]
				
				let entity = managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName[request.entityName!]!
				let propertiesByName = entity.propertiesByName
				var properties = [NSPropertyDescription]()
				properties.append(propertiesByName["typeID"]!)
				properties.append(propertiesByName["typeName"]!)
				properties.append(NSExpressionDescription(name: "icon", resultType: .objectIDAttributeType, expression: NSExpression(forKeyPath: "icon")))
				properties.append(NSExpressionDescription(name: "groupName", resultType: .stringAttributeType, expression: NSExpression(forKeyPath: "group.groupName")))
				request.propertiesToFetch = properties
				request.resultType = .dictionaryResultType
				
				let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "groupName", cacheName: nil)
				try? results.performFetch()

				if results.fetchedObjects?.isEmpty == false {
					row.isExpandable = true
					row.isExpanded = false
					
					row.children = [FetchedResultsNode(resultsController: results, sectionNode: NCDefaultFetchedResultsSectionCollapsedNode<NSDictionary>.self, objectNode: NCDatabaseTypeRow<NSDictionary>.self)]
				}
				
				rows.append(row)

			}

			if wh.maxRegeneration > 0 {
				rows.append(NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
				                                  nodeIdentifier: "MaximumMassRegeneration",
				                                  image: eveIcons["23_03"]?.image?.image,
				                                  title: NSLocalizedString("Maximum Mass Regeneration", comment: "").uppercased(),
				                                  subtitle: NCUnitFormatter.localizedString(from: wh.maxRegeneration, unit: .kilogram, style: .full)))
				
			}
			
		})
	}
	
	static func subskills(skill: NCDBInvType, character: NCCharacter) -> [NCDatabaseTypeSkillRow] {
		var rows = [NCDatabaseTypeSkillRow]()
		for requiredSkill in skill.requiredSkills?.array as? [NCDBInvTypeRequiredSkill] ?? [] {
			guard let type = requiredSkill.skillType else {continue}
			let row = NCDatabaseTypeSkillRow(skill: requiredSkill, character: character, children: subskills(skill: type, character: character))
			rows.append(row)
		}
		return rows
	}

	
	static func requiredSkills(type: NCDBInvType, character: NCCharacter) -> NCDatabaseSkillsSection? {
		var rows = [TreeNode]()
		for requiredSkill in type.requiredSkills?.array as? [NCDBInvTypeRequiredSkill] ?? [] {
			guard let type = requiredSkill.skillType else {continue}
			let row = NCDatabaseTypeSkillRow(skill: requiredSkill, character: character, children: subskills(skill: type, character: character))
			rows.append(row)
		}
		guard !rows.isEmpty else {return nil}
		let trainingQueue = NCTrainingQueue(character: character)
		trainingQueue.addRequiredSkills(for: type)
		return NCDatabaseSkillsSection(nodeIdentifier: String(NCDBAttributeCategoryID.requiredSkills.rawValue), title: NSLocalizedString("Required Skills", comment: "").uppercased(), trainingQueue: trainingQueue, character: character, children: rows)
	}
	
	static func requiredSkills(activity: NCDBIndActivity, character: NCCharacter) -> NCDatabaseSkillsSection? {
		var rows = [TreeNode]()
		for requiredSkill in activity.requiredSkills?.sortedArray(using: [NSSortDescriptor(key: "skillType.typeName", ascending: true)]) as? [NCDBIndRequiredSkill] ?? [] {
			guard let type = requiredSkill.skillType else {continue}
			let row = NCDatabaseTypeSkillRow(skill: requiredSkill, character: character, children: subskills(skill: type, character: character))
			rows.append(row)
		}
		
		let trainingQueue = NCTrainingQueue(character: character)
		trainingQueue.addRequiredSkills(for: activity)
		return !rows.isEmpty ? NCDatabaseSkillsSection(nodeIdentifier: "RequiredSkills.\(activity.activity?.activityName ?? "")", title: NSLocalizedString("Required Skills", comment: "").uppercased(), trainingQueue: trainingQueue, character: character, children: rows) : nil
	}
	
	static func masteries(type: NCDBInvType, character: NCCharacter) -> TreeSection? {
		var masteries = [Int: [NCDBCertMastery]]()
		for certificate in type.certificates?.allObjects as? [NCDBCertCertificate] ?? [] {
			for mastery in certificate.masteries?.array as? [NCDBCertMastery] ?? [] {
				let level = Int(mastery.level?.level ?? 0)
				var array = masteries[level] ?? []
				array.append(mastery)
				masteries[level] = array
			}
		}
		let unclaimedIcon = NCDBEveIcon.eveIcons(managedObjectContext: type.managedObjectContext!)[NCDBEveIcon.File.certificateUnclaimed.rawValue]
		var rows = [NCDatabaseTypeInfoRow]()
		for (key, array) in masteries.sorted(by: {return $0.key < $1.key}) {
			guard let level = array.first?.level else {continue}
			let trainingQueue = NCTrainingQueue(character: character)
			for mastery in array {
				trainingQueue.add(mastery: mastery)
			}
			let trainingTime = trainingQueue.trainingTime(characterAttributes: character.attributes)
			let title = NSLocalizedString("Level", comment: "").uppercased() + " \(String(romanNumber: key + 1))"
			let subtitle = trainingTime > 0 ? NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
			let icon = trainingTime > 0 ? unclaimedIcon : level.icon
			let row = NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
			                                image: icon?.image?.image,
			                                title: title,
			                                subtitle: subtitle,
			                                accessoryType: .disclosureIndicator,
			                                route: Router.Database.TypeMastery(typeObjectID: type.objectID, masteryLevelObjectID: level.objectID))
			rows.append(row)
		}
		
		if rows.count > 0 {
			return DefaultTreeSection(nodeIdentifier: "Mastery", title: NSLocalizedString("Mastery", comment: "").uppercased(), children: rows)
		}
		else {
			return nil
		}
	}
	
	static func skillPlan(type: NCDBInvType, character: NCCharacter) -> TreeSection? {
		guard NCDBCategoryID(rawValue: Int(type.group?.category?.categoryID ?? 0)) == .skill else {return nil}
		var rows = [TreeRow]()
		for i in 1...5 {
//			let trainingQueue = NCTrainingQueue(character: character)
//			trainingQueue.add(skill: type, level: i)
			let row = NCDatabaseTrainingSkillRow(skill: type, level: i, character: character)
			guard row.trainingTime > 0 else {continue}
//			let t = trainingQueue.trainingTime(characterAttributes: character.attributes)
//			guard t > 0 else {continue}
//			let row = NCDatabaseTypeInfoRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
//			                                image: #imageLiteral(resourceName: "skills"),
//			                                title: NSLocalizedString("Train to Level", comment: "").uppercased() + " \(i)",
//			                                subtitle: NCTimeIntervalFormatter.localizedString(from: t, precision: .seconds),
//			                                object: trainingQueue)
			rows.append(row)

		}
		guard !rows.isEmpty else {return nil}
		return DefaultTreeSection(nodeIdentifier: "SkillPlan", title: NSLocalizedString("Skill Plan", comment: "").uppercased(), children: rows)
	}
	
}
