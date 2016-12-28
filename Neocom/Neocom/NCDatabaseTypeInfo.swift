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
	let object: Any?
	let segue: String?
	
	init(title: String?, subtitle: String?, image: UIImage?, object: Any?, segue: String? = nil) {
		self.title = title
		self.subtitle = subtitle
		self.image = image
		self.object = object
		self.segue = segue
		super.init(cellIdentifier: "Cell")
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
	let object: Any?
	let tintColor: UIColor?
	let subtitle: String?
	
	init(skill: NCDBInvTypeRequiredSkill, character: NCCharacter, children: [NCTreeNode]?) {
		self.title = NSAttributedString(skillName: skill.skillType!.typeName!, level: Int(skill.skillLevel))

		let trainingTime: TimeInterval
		
		if let type = skill.skillType, let trainedSkill = character.skills[Int(type.typeID)], let trainedLevel = trainedSkill.level {
			if trainedLevel >= Int(skill.skillLevel) {
				self.image = UIImage(named: "skillRequirementMe")
				self.tintColor = UIColor.white
				trainingTime = 0
			}
			else {
				trainingTime = NCTrainingSkill(type: type, skill: trainedSkill, level: Int(skill.skillLevel))?.trainingTime(characterAttributes: character.attributes) ?? 0
				self.image = UIImage(named: "skillRequirementNotMe")
				self.tintColor = UIColor.lightText
			}
		}
		else {
			if let type = skill.skillType {
				trainingTime = NCTrainingSkill(type: type, level: Int(skill.skillLevel))?.trainingTime(characterAttributes: character.attributes) ?? 0
			}
			else {
				trainingTime = 0
			}
			self.image = UIImage(named: "skillRequirementNotInjected")
			self.tintColor = UIColor.lightText
		}
		self.object = skill.skillType?.objectID
		self.subtitle = trainingTime > 0 ? NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
		
		super.init(cellIdentifier: "Cell", nodeIdentifier: nil, children: children)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCDefaultTableViewCell
		cell.titleLabel?.attributedText = title
		cell.subtitleLabel?.text = subtitle
		cell.subtitleLabel?.textColor = self.tintColor
		cell.iconView?.image = image
		cell.iconView?.tintColor = self.tintColor
		cell.object = object
		cell.accessoryType = .disclosureIndicator
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
	let history: NSManagedObjectID
	var observer: NCManagedObjectObserver?
	weak var cell: NCMarketHistoryTableViewCell?
	
	init(history: NSManagedObjectID) {
		self.history = history
		super.init(cellIdentifier: "NCMarketHistoryTableViewCell")
		self.observer = NCManagedObjectObserver(managedObjectID: history)  {[weak self] (_, _) in
			self?.reload()
		}
		reload()
	}
	
	func reload() {
		NCCache.sharedCache?.performBackgroundTask { managedObjectContext in
			guard let record = (try? managedObjectContext.existingObject(with: self.history)) as? NCCacheRecord else {return}
			guard let history = record.data?.data as? [ESMarketHistory] else {return}
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
					h += item.highest / n
					h2 += (item.highest * item.highest) / n
					l += item.lowest / n
					l2 += (item.lowest * item.lowest) / n
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
			
			var v = 0...0 as ClosedRange<Int>
			var p = 0...0 as ClosedRange<Double>
			let d = history[range.first!].date...history[range.last!].date
			var prevT: TimeInterval?
			
			var lowest = Double.greatestFiniteMagnitude as Double
			var highest = 0 as Double
			
			for i in range {
				let item = history[i]
				if visibleRange.contains(item.lowest) {
					lowest = min(lowest, item.lowest)
				}
				if visibleRange.contains(item.highest) {
					highest = max(highest, item.highest)
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
				p = min(p.lowerBound, lowest.lowest)...max(p.upperBound, highest.highest)
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
		let cell = cell as! NCDamageTypeTableViewCell
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

class NCDatabaseTypeInfo {
	
	class func typeInfo(type: NCDBInvType, completionHandler: @escaping ([NCTreeSection]) -> Void) {

		var marketSection: NCTreeSection?
		if type.marketGroup != nil {
			let regionID = (UserDefaults.standard.value(forKey: UserDefaults.Key.NCMarketRegion) as? Int) ?? NCDBRegionID.theForge.rawValue
			let typeID = Int(type.typeID)
			marketSection = NCTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Market", title: NSLocalizedString("Market", comment: "").uppercased(), children: [])
			
			let dataManager = NCDataManager(account: NCAccount.current)
			
			dataManager.marketHistory(typeID: typeID, regionID: regionID) { result in
				switch result {
				case let .success(value: _, cacheRecordID: recordID):
					let row = NCDatabaseTypeMarketRow(history: recordID)
					marketSection?.mutableArrayValue(forKey: "children").add(row)
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
		itemInfo(type: type) { result in
			var sections = result
			if let marketSection = marketSection {
				sections.insert(marketSection, at: 0)
			}
			completionHandler(sections)
		}
	}
	
	class func itemInfo(type: NCDBInvType, completionHandler: @escaping ([NCTreeSection]) -> Void) {
		
		NCCharacter.load(account: NCAccount.current) { character in
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
	
	class func requiredSkills(type: NCDBInvType, character: NCCharacter) -> NCTreeSection {
		var rows = [NCTreeNode]()
		for requiredSkill in type.requiredSkills?.array as? [NCDBInvTypeRequiredSkill] ?? [] {
			guard let type = requiredSkill.skillType else {continue}
			
			func subskills(skill: NCDBInvType) -> [NCDatabaseTypeSkillRow] {
				var rows = [NCDatabaseTypeSkillRow]()
				for requiredSkill in skill.requiredSkills?.array as? [NCDBInvTypeRequiredSkill] ?? [] {
					guard let type = requiredSkill.skillType else {continue}
					let row = NCDatabaseTypeSkillRow(skill: requiredSkill, character: character, children: subskills(skill: type))
					rows.append(row)
				}
				return rows
			}
			
			let row = NCDatabaseTypeSkillRow(skill: requiredSkill, character: character, children: subskills(skill: type))
			rows.append(row)
		}
		let trainingQueue = NCTrainingQueue(character: character)
		trainingQueue.addRequiredSkills(for: type)
		let trainingTime = trainingQueue.trainingTime(characterAttributes: character.attributes)
		let title = NSMutableAttributedString(string: NSLocalizedString("Required Skills", comment: "").uppercased())
		if trainingTime > 0 {
			title.append(NSAttributedString(
				string: " (\(NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds)))",
				attributes: [NSForegroundColorAttributeName: UIColor.white]))
		}
		return NCTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: String(NCDBAttributeCategoryID.requiredSkills.rawValue), title: nil, attributedTitle: title, children: rows, configurationHandler: nil)
	}
	
	class func masteries(type: NCDBInvType, character: NCCharacter) -> NCTreeSection? {
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
			let title = NSLocalizedString("LEVEL", comment: "") + " \(String(romanNumber: key + 1))"
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
