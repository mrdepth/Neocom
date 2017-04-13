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

class NCDatabaseTypeInfoRow: NCTreeRow {
	let title: String?
	let subtitle: String?
	let image: UIImage?
	let segue: String?
	
	init(title: String?, subtitle: String?, image: UIImage?, object: Any?, segue: String? = nil) {
		self.title = title
		self.subtitle = subtitle
		self.image = image
		self.segue = segue
		super.init(cellIdentifier: "Cell", object: object)
	}
	
	convenience init?(attribute: NCDBDgmTypeAttribute) {
		func toString(_ value: Float, _ unit: String?) -> String {
			var s = NCUnitFormatter.localizedString(from: Double(value), unit: .none, style: .full)
			if let unit = unit {
				s += " " + unit
			}
			return s
		}
		guard let attributeType = attribute.attributeType else {return nil}
		
		var title: String?
		var subtitle: String?
		var image: UIImage?
		var object: Any?
		var segue: String?

		switch NCDBUnitID(rawValue: Int(attributeType.unit?.unitID ?? 0)) ?? NCDBUnitID.none {
		case .attributeID:
			guard let attributeType = NCDBDgmAttributeType.dgmAttributeTypes(managedObjectContext: attribute.managedObjectContext!)[Int(attribute.value)] else {break}
			subtitle = attributeType.displayName ?? attributeType.attributeName ?? ""
			
		case .groupID:
			guard let group = NCDBInvGroup.invGroups(managedObjectContext: attribute.managedObjectContext!)[Int(attribute.value)] else {break}
			image = attributeType.icon?.image?.image ?? group.icon?.image?.image
			subtitle = group.groupName ?? ""
			object = group.objectID
			segue = "NCDatabaseTypesViewController"
			break
		case .typeID:
			guard let type = NCDBInvType.invTypes(managedObjectContext: attribute.managedObjectContext!)[Int(attribute.value)] else {break}
			image = type.icon?.image?.image ?? attributeType.icon?.image?.image
			subtitle = type.typeName ?? ""
			object = type.objectID
			segue = "NCDatabaseTypeInfoViewController"
			break
		case .sizeClass:
			switch Int(attribute.value) {
			case 1:
				subtitle = NSLocalizedString("Small", comment: "")
			case 2:
				subtitle = NSLocalizedString("Medium", comment: "")
			case 3:
				subtitle = NSLocalizedString("Large", comment: "")
			default:
				subtitle = NSLocalizedString("X-Large", comment: "")
			}
		case .bonus:
			subtitle = "+" + NCUnitFormatter.localizedString(from: Double(attribute.value), unit: .none, style: .full)
			image = attributeType.icon?.image?.image
		case .boolean:
			subtitle = Int(attribute.value) == 0 ? NSLocalizedString("No", comment: "") : NSLocalizedString("Yes", comment: "")
		case .inverseAbsolutePercent, .inversedModifierPercent:
			subtitle = toString((1.0 - attribute.value) * 100.0, attributeType.unit?.displayName)
		case .modifierPercent:
			subtitle = toString((attribute.value - 1.0) * 100.0, attributeType.unit?.displayName)
		case .absolutePercent:
			subtitle = toString(attribute.value * 100.0, attributeType.unit?.displayName)
		case .milliseconds:
			subtitle = toString(attribute.value / 1000.0, attributeType.unit?.displayName)
		default:
			subtitle = toString(attribute.value, attributeType.unit?.displayName)
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
		self.init(title: title?.uppercased(), subtitle: subtitle, image: image, object: object, segue: segue)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCDefaultTableViewCell
		cell.titleLabel?.text = title
		cell.titleLabel?.textColor = UIColor.caption
		cell.subtitleLabel?.text = subtitle
		cell.subtitleLabel?.textColor = UIColor.white
		cell.iconView?.image = image
		cell.object = object
		if segue != nil {
			cell.accessoryView = nil
			cell.accessoryType = .disclosureIndicator
		}
		else {
			cell.accessoryView = nil
			cell.accessoryType = .none
		}
	}

}

class NCDatabaseTypeSkillRow: NCTreeNode {
	let title: NSAttributedString?
	let image: UIImage?
	let subtitle: String?
	let trainingTime: TimeInterval
	let skill: NCTrainingSkill?
	
	init(skill: NCDBInvType, level: Int, character: NCCharacter, children: [NCTreeNode]?) {
		self.title = NSAttributedString(skillName: skill.typeName!, level: level)
		
		if let trainedSkill = character.skills[Int(skill.typeID)], let trainedLevel = trainedSkill.level {
			if trainedLevel >= level {
				self.image = UIImage(named: "skillRequirementMe")
				trainingTime = 0
				self.skill = nil
			}
			else {
				self.skill = NCTrainingSkill(type: skill, skill: trainedSkill, level: level)
				trainingTime = self.skill?.trainingTime(characterAttributes: character.attributes) ?? 0
				self.image = UIImage(named: "skillRequirementNotMe")
			}
		}
		else {
			self.skill = NCTrainingSkill(type: skill, level: level)
			trainingTime = self.skill?.trainingTime(characterAttributes: character.attributes) ?? 0
			self.image = UIImage(named: "skillRequirementNotInjected")
		}
		self.subtitle = trainingTime > 0 ? NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
		
		super.init(cellIdentifier: "Cell", nodeIdentifier: nil, children: children, object: skill.objectID)
	}
	
	convenience init(skill: NCDBInvTypeRequiredSkill, character: NCCharacter, children: [NCTreeNode]? = nil) {
		self.init(skill: skill.skillType!, level: Int(skill.skillLevel), character: character, children: children)
	}

	convenience init(skill: NCDBIndRequiredSkill, character: NCCharacter, children: [NCTreeNode]? = nil) {
		self.init(skill: skill.skillType!, level: Int(skill.skillLevel), character: character, children: children)
	}

	convenience init(skill: NCDBCertSkill, character: NCCharacter, children: [NCTreeNode]? = nil) {
		self.init(skill: skill.type!, level: Int(skill.skillLevel), character: character, children: children)
	}

	override func configure(cell: UITableViewCell) {
		let tintColor = trainingTime > 0 ? UIColor.lightText : UIColor.white
		let cell = cell as! NCDefaultTableViewCell
		cell.titleLabel?.attributedText = title
		cell.subtitleLabel?.text = subtitle
		cell.subtitleLabel?.textColor = tintColor
		cell.iconView?.image = image
		cell.iconView?.tintColor = tintColor
		cell.object = object
		cell.accessoryType = .disclosureIndicator
		
		if let skill = self.skill, trainingTime > 0 {
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
	
	override var canExpand: Bool {
		return false
	}
}

class NCDatabaseTypeMarketRow: NCTreeRow {
	var volume: UIBezierPath?
	var median: UIBezierPath?
	var donchian: UIBezierPath?
	var donchianVisibleRange: CGRect?
	var date: ClosedRange<Date>?
	let history: NCCacheRecord
	var observer: NCManagedObjectObserver?
	weak var cell: NCMarketHistoryTableViewCell?
	
	init(history: NCCacheRecord) {
		self.history = history
		super.init(cellIdentifier: "NCMarketHistoryTableViewCell")
		self.observer = NCManagedObjectObserver(managedObject: history)  {[weak self] (_, _) in
			self?.reload()
		}
		reload()
	}
	
	func reload() {
		NCCache.sharedCache?.performBackgroundTask { managedObjectContext in
			guard let record = (try? managedObjectContext.existingObject(with: self.history.objectID)) as? NCCacheRecord else {return}
			guard let history = record.data?.data as? [ESI.Market.History] else {return}
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
				if let cell = self.cell {
					self.configure(cell: cell)
				}
			}
		}
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCMarketHistoryTableViewCell
		self.cell = cell
		cell.marketHistoryView.volume = volume
		cell.marketHistoryView.median = median
		cell.marketHistoryView.donchian = donchian
		cell.marketHistoryView.donchianVisibleRange = donchianVisibleRange
		cell.marketHistoryView.date = date
	}
}

class NCDatabaseTypeResistanceRow: NCTreeRow {
	var em: Float = 0
	var thermal: Float = 0
	var kinetic: Float = 0
	var explosive: Float = 0
	
	init() {
		super.init(cellIdentifier: "NCDamageTypeTableViewCell")
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

class NCDatabaseTypeDamageRow: NCTreeRow {
	var em: Float = 0
	var thermal: Float = 0
	var kinetic: Float = 0
	var explosive: Float = 0
	
	init() {
		super.init(cellIdentifier: "NCDamageTypeTableViewCell")
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

class NCDatabaseSkillsSection: NCTreeSection {
	let trainingQueue: NCTrainingQueue
	let character: NCCharacter
	let trainingTime: TimeInterval
	
	init(nodeIdentifier: String?, title: String?, trainingQueue: NCTrainingQueue, character: NCCharacter, children: [NCTreeNode]? = nil) {
		self.trainingQueue = trainingQueue
		self.character = character
		trainingTime = trainingQueue.trainingTime(characterAttributes: character.attributes)
		let attributedTitle = NSMutableAttributedString(string: title ?? "")
		if trainingTime > 0 {
			attributedTitle.append(NSAttributedString(
				string: " (\(NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds)))",
				attributes: [NSForegroundColorAttributeName: UIColor.white]))
		}
		super.init(cellIdentifier: "NCSkillsHeaderTableViewCell", nodeIdentifier: nodeIdentifier, attributedTitle: attributedTitle, children: children)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCSkillsHeaderTableViewCell
		cell.titleLabel?.attributedText = attributedTitle
		cell.trainButton?.isHidden = NCAccount.current == nil || trainingTime == 0
		cell.trainingQueue = trainingQueue
		cell.character = character
	}
}

struct NCDatabaseTypeInfo {
	
	static func typeInfo(type: NCDBInvType, completionHandler: @escaping ([NCTreeSection]) -> Void) {

		var marketSection: NCTreeSection?
		if type.marketGroup != nil {
			let regionID = (UserDefaults.standard.value(forKey: UserDefaults.Key.NCMarketRegion) as? Int) ?? NCDBRegionID.theForge.rawValue
			let typeID = Int(type.typeID)
			marketSection = NCTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Market", title: NSLocalizedString("Market", comment: "").uppercased(), children: [])
			
			let dataManager = NCDataManager(account: NCAccount.current)
			
			dataManager.marketHistory(typeID: typeID, regionID: regionID) { result in
				switch result {
				case let .success(_, cacheRecord):
					if let cacheRecord = cacheRecord {
						let row = NCDatabaseTypeMarketRow(history: cacheRecord)
						marketSection?.mutableArrayValue(forKey: "children").add(row)
					}
				default:
					break
				}
			}
			
			dataManager.prices(typeIDs: [typeID]) { result in
				guard let price = result[typeID] else {return}
				let subtitle = NCUnitFormatter.localizedString(from: price, unit: .isk, style: .full)
				let row = NCDatabaseTypeInfoRow(title: NSLocalizedString("PRICE", comment: ""), subtitle: subtitle, image: UIImage(named: "wallet"), object: nil, segue: "NCDatabaseMarketInfoViewController")
				marketSection?.mutableArrayValue(forKey: "children").insert(row, at: 0)
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
			break
		default:
			itemInfo(type: type) { result in
				var sections = result
				if let marketSection = marketSection {
					sections.insert(marketSection, at: 0)
				}
				completionHandler(sections)
			}
		}

	}
	
	static func itemInfo(type: NCDBInvType, completionHandler: @escaping ([NCTreeSection]) -> Void) {
		
		NCCharacter.load(account: NCAccount.current) { result in
			let character: NCCharacter
			switch result {
			case let .success(value):
				character = value
			default:
				character = NCCharacter()
			}

			NCDatabase.sharedDatabase?.performBackgroundTask({ (managedObjectContext) in
				var sections = [NCTreeSection]()
				
				defer {
					DispatchQueue.main.async {
						completionHandler(sections)
					}
				}
				
				guard let type = (try? managedObjectContext.existingObject(with: type.objectID)) as? NCDBInvType else {return}
				
				if let mastery = NCDatabaseTypeInfo.masteries(type: type, character: character) {
					sections.append(mastery)
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
						sections.append(requiredSkills(type: type, character: character))
					}
					else {
						let sectionTitle: String
						if Int(attributeCategory.categoryID) == NCDBAttributeCategoryID.null.rawValue {
							sectionTitle = NSLocalizedString("Other", comment: "")
						}
						else {
							sectionTitle = attributeCategory.categoryName ?? NSLocalizedString("Other", comment: "")
						}
						
						var rows = [NCTreeNode]()
						
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
							case .emDamage:
								damage()?.em = attribute.value
							case .thermalDamage:
								damage()?.thermal = attribute.value
							case .kineticDamage:
								damage()?.kinetic = attribute.value
							case .explosiveDamage:
								damage()?.explosive = attribute.value

							case .warpSpeedMultiplier:
								guard let attributeType = attribute.attributeType else {continue}
								let baseWarpSpeed = type.allAttributes[NCDBAttributeID.baseWarpSpeed.rawValue]?.value ?? 1.0
								var s = NCUnitFormatter.localizedString(from: Double(attribute.value * baseWarpSpeed), unit: .none, style: .full)
								s += " " + NSLocalizedString("AU/sec", comment: "")
								rows.append(NCDatabaseTypeInfoRow(title: NSLocalizedString("Warp Speed", comment: ""), subtitle: s, image: attributeType.icon?.image?.image, object: nil))
							default:
								guard let row = NCDatabaseTypeInfoRow(attribute: attribute) else {continue}
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
							sections.append(NCTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: String(attributeCategory.categoryID), title: sectionTitle.uppercased(), attributedTitle: nil, children: rows, configurationHandler: nil))
						}
					}
				}
			})

		}
	}

	static func blueprintInfo(type: NCDBInvType, completionHandler: @escaping ([NCTreeSection]) -> Void) {
		
		NCCharacter.load(account: NCAccount.current) { result in
			let character: NCCharacter
			switch result {
			case let .success(value):
				character = value
			default:
				character = NCCharacter()
			}

			NCDatabase.sharedDatabase?.performBackgroundTask({ (managedObjectContext) in
				var sections = [NCTreeSection]()
				
				defer {
					DispatchQueue.main.async {
						completionHandler(sections)
					}
				}
				
				guard let type = (try? managedObjectContext.existingObject(with: type.objectID)) as? NCDBInvType else {return}
				guard let blueprintType = type.blueprintType else {return}
				for activity in blueprintType.activities?.sortedArray(using: [NSSortDescriptor(key: "activity.activityID", ascending: true)]) as? [NCDBIndActivity] ?? [] {
					var rows = [NCTreeNode]()
					rows.append(NCDatabaseTypeInfoRow(title: NSLocalizedString("TIME", comment: ""), subtitle: NCTimeIntervalFormatter.localizedString(from: TimeInterval(activity.time), precision: .seconds), image: nil, object: nil))
					for product in activity.products?.sortedArray(using: [NSSortDescriptor(key: "productType.typeName", ascending: true)]) as? [NCDBIndProduct] ?? [] {
						guard let type = product.productType, let subtitle = type.typeName else {continue}
						let title = NSLocalizedString("PRODUCT", comment: "")
						let image = type.icon?.image?.image
						rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: subtitle, image: image, object: type.objectID, segue: "NCDatabaseTypeInfoViewController"))
					}
					
					var materials = [NCTreeNode]()
					for material in activity.requiredMaterials?.sortedArray(using: [NSSortDescriptor(key: "materialType.typeName", ascending: true)]) as? [NCDBIndRequiredMaterial] ?? [] {
						guard let type = material.materialType, let title = type.typeName else {continue}
						let subtitle = NCUnitFormatter.localizedString(from: material.quantity, unit: .none, style: .full)
						let image = type.icon?.image?.image
						materials.append(NCDatabaseTypeInfoRow(title: title, subtitle: subtitle, image: image, object: type.objectID, segue: "NCDatabaseTypeInfoViewController"))
					}
					if materials.count > 0 {
						rows.append(NCTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: nil, title: NSLocalizedString("MATERIALS", comment: ""), attributedTitle: nil, children: materials))
					}
					
					if let skills = requiredSkills(activity: activity, character: character) {
						rows.append(skills)
					}
					
					sections.append(NCTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: nil, title: activity.activity?.activityName?.uppercased(), attributedTitle: nil, children: rows))
				}
				
			})
			
		}
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

	
	static func requiredSkills(type: NCDBInvType, character: NCCharacter) -> NCDatabaseSkillsSection {
		var rows = [NCTreeNode]()
		for requiredSkill in type.requiredSkills?.array as? [NCDBInvTypeRequiredSkill] ?? [] {
			guard let type = requiredSkill.skillType else {continue}
			let row = NCDatabaseTypeSkillRow(skill: requiredSkill, character: character, children: subskills(skill: type, character: character))
			rows.append(row)
		}
		let trainingQueue = NCTrainingQueue(character: character)
		trainingQueue.addRequiredSkills(for: type)
		return NCDatabaseSkillsSection(nodeIdentifier: String(NCDBAttributeCategoryID.requiredSkills.rawValue), title: NSLocalizedString("Required Skills", comment: "").uppercased(), trainingQueue: trainingQueue, character: character, children: rows)
	}
	
	static func requiredSkills(activity: NCDBIndActivity, character: NCCharacter) -> NCDatabaseSkillsSection? {
		var rows = [NCTreeNode]()
		for requiredSkill in activity.requiredSkills?.sortedArray(using: [NSSortDescriptor(key: "skillType.typeName", ascending: true)]) as? [NCDBIndRequiredSkill] ?? [] {
			guard let type = requiredSkill.skillType else {continue}
			let row = NCDatabaseTypeSkillRow(skill: requiredSkill, character: character, children: subskills(skill: type, character: character))
			rows.append(row)
		}
		
		let trainingQueue = NCTrainingQueue(character: character)
		trainingQueue.addRequiredSkills(for: activity)
		return NCDatabaseSkillsSection(nodeIdentifier: nil, title: NSLocalizedString("Required Skills", comment: "").uppercased(), trainingQueue: trainingQueue, character: character, children: rows)
	}
	
	static func masteries(type: NCDBInvType, character: NCCharacter) -> NCTreeSection? {
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
			let row = NCDatabaseTypeInfoRow(title: title, subtitle: subtitle, image: icon?.image?.image, object: level.objectID, segue: "NCDatabaseCertificateMasteryViewController")
			rows.append(row)
		}
		
		if rows.count > 0 {
			return NCTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Mastery", title: NSLocalizedString("Mastery", comment: "").uppercased(), children: rows)
		}
		else {
			return nil
		}
	}
	
}
