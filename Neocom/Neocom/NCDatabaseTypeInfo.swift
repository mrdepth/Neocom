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
	let accessory: UIImage?
	let object: Any?
	let segue: String?
	
	init(title: String?, subtitle: String?, image: UIImage?, accessory: UIImage?, object: Any?, segue: String? = nil) {
		self.title = title
		self.subtitle = subtitle
		self.image = image
		self.accessory = accessory
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
		var accessory: UIImage?
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
				subtitle = NSLocalizedString("XL", comment: "")
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
		self.init(title: title, subtitle: subtitle, image: image, accessory: accessory, object: object, segue: segue)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCDefaultTableViewCell
		cell.titleLabel?.text = title
		cell.subtitleLabel?.text = subtitle
		cell.iconView?.image = image
		if let accessory = accessory {
			cell.accessoryView = UIImageView(image: accessory)
		}
		else {
			cell.accessoryView = nil
		}
	}

}

class NCDatabaseTypeSkillRow: NCTreeNode {
	let title: String?
	let image: UIImage?
	let accessory: UIImage?
	let object: Any?
	let tintColor: UIColor?
	let subtitle: String?
	
	init(skill: NCDBInvTypeRequiredSkill, character: NCCharacter, children: [NCTreeNode]?) {
		self.title = "\(skill.skillType!.typeName!) - \(skill.skillLevel)"
		//let eveIcons = NCDBEveIcon.eveIcons(managedObjectContext: skill.managedObjectContext!)
		//self.image = eveIcons["50_11"]?.image?.image
		self.accessory = nil
		
		let trainingTime: TimeInterval
		
		if let type = skill.skillType, let trainedSkill = character.skills[Int(type.typeID)], let trainedLevel = trainedSkill.level {
			//self.image = eveIcons[trainedLevel >= Int(skill.skillLevel) ? "38_193" : "38_195"]?.image?.image
			if trainedLevel >= Int(skill.skillLevel) {
				self.image = UIImage(named: "skillRequirementMe")
				self.tintColor = UIColor.caption
				trainingTime = 0
			}
			else {
				trainingTime = NCTrainingSkill(type: type, skill: trainedSkill, level: Int(skill.skillLevel))?.trainingTime(characterAttributes: character.attributes) ?? 0
				self.image = UIImage(named: "skillRequirementNotMe")
				self.tintColor = UIColor.lightGray
			}
		}
		else {
			if let type = skill.skillType {
				trainingTime = NCTrainingSkill(type: type, level: Int(skill.skillLevel))?.trainingTime(characterAttributes: character.attributes) ?? 0
			}
			else {
				trainingTime = 0
			}
			//self.image = eveIcons["38_194"]?.image?.image
			self.image = UIImage(named: "skillRequirementNotInjected")
			self.tintColor = UIColor.lightGray
		}
		self.object = skill.skillType
		self.subtitle = trainingTime > 0 ? NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
		
		super.init(cellIdentifier: "Cell", nodeIdentifier: nil, children: children)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCDefaultTableViewCell
		cell.titleLabel?.text = title
		cell.subtitleLabel?.text = subtitle
		cell.iconView?.image = image
		cell.iconView?.tintColor = self.tintColor
		if let accessory = accessory {
			cell.accessoryView = UIImageView(image: accessory)
		}
		else {
			cell.accessoryView = nil
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
			guard let date = history.last?.date.addingTimeInterval(-3600 * 24 * 90) else {return}
			guard let i = history.index(where: {
				$0.date > date
			}) else {
				return
			}
			
			let range = history.suffix(from: i).indices
			
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
			
			for i in range {
				let item = history[i]
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
			
			donchian.close()
			DispatchQueue.main.async {
				self.volume = volume
				self.median = avg
				self.donchian = donchian
				self.date = d
				if let cell = self.cell {
					self.configure(cell: cell)
				}
			}
		}
	}
	
	/*init(history: [ESMarketHistory], volume: UIBezierPath, median: UIBezierPath, donchian: UIBezierPath, date: ClosedRange<Date>) {
		self.volume = volume
		self.median = median
		self.donchian = donchian
		self.date = date
		super.init(cellIdentifier: "NCMarketHistoryTableViewCell")
	}*/
	
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCMarketHistoryTableViewCell
		self.cell = cell
		cell.marketHistoryView.volume = volume
		cell.marketHistoryView.median = median
		cell.marketHistoryView.donchian = donchian
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

class NCDatabaseTypeInfo {
	
	class func typeInfo(type: NCDBInvType, completionHandler: @escaping ([NCTreeSection]) -> Void) {

		var marketSection: NCTreeSection?
		if type.marketGroup != nil {
			let regionID = (UserDefaults.standard.value(forKey: UserDefaults.Key.NCMarketRegion) as? Int) ?? NCDBRegionID.theForge.rawValue
			let typeID = Int(type.typeID)
			marketSection = NCTreeSection(cellIdentifier: "NCTableViewHeaderCell", nodeIdentifier: "Market", title: NSLocalizedString("Market", comment: "").uppercased(), children: [])
			
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
				let row = NCDatabaseTypeInfoRow(title: NSLocalizedString("Price", comment: ""), subtitle: subtitle, image: UIImage(named: "wallet"), accessory: nil, object: nil)
				marketSection?.mutableArrayValue(forKey: "children").insert(row, at: 0)
			}
		}
		shipInfo(type: type) { result in
			var sections = result
			if let marketSection = marketSection {
				sections.insert(marketSection, at: 0)
			}
			completionHandler(sections)
		}
	}
	
	class func shipInfo(type: NCDBInvType, completionHandler: @escaping ([NCTreeSection]) -> Void) {
		
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
						
						let resistanceRow: NCDatabaseTypeResistanceRow?
						switch NCDBAttributeCategoryID(rawValue: Int(attributeCategory.categoryID)) ?? NCDBAttributeCategoryID.none {
						case .shield:
							resistanceRow = NCDatabaseTypeResistanceRow()
						case .armor:
							resistanceRow = NCDatabaseTypeResistanceRow()
						case .structure:
							resistanceRow = NCDatabaseTypeResistanceRow()
						default:
							resistanceRow = nil
						}
						
						for attribute in (section.objects as? [NCDBDgmTypeAttribute]) ?? [] {
							switch NCDBAttributeID(rawValue: Int(attribute.attributeType!.attributeID)) ?? NCDBAttributeID.none {
							case .emDamageResonance, .armorEmDamageResonance, .shieldEmDamageResonance:
								resistanceRow?.em = 1 - attribute.value
							case .thermalDamageResonance, .armorThermalDamageResonance, .shieldThermalDamageResonance:
								resistanceRow?.thermal = 1 - attribute.value
							case .kineticDamageResonance, .armorKineticDamageResonance, .shieldKineticDamageResonance:
								resistanceRow?.kinetic = 1 - attribute.value
							case .explosiveDamageResonance, .armorExplosiveDamageResonance, .shieldExplosiveDamageResonance:
								resistanceRow?.explosive = 1 - attribute.value
							case .warpSpeedMultiplier:
								guard let attributeType = attribute.attributeType else {continue}
								let baseWarpSpeed = type.allAttributes[NCDBAttributeID.baseWarpSpeed.rawValue]?.value ?? 1.0
								var s = NCUnitFormatter.localizedString(from: Double(attribute.value * baseWarpSpeed), unit: .none, style: .full)
								s += " " + NSLocalizedString("AU/sec", comment: "")
								rows.append(NCDatabaseTypeInfoRow(title: NSLocalizedString("Warp Speed", comment: ""), subtitle: s, image: attributeType.icon?.image?.image, accessory: nil, object: nil))
							default:
								guard let row = NCDatabaseTypeInfoRow(attribute: attribute) else {continue}
								rows.append(row)
							}
						}
						
						if let resistanceRow = resistanceRow {
							rows.append(resistanceRow)
							
						}
						if rows.count > 0 {
							sections.append(NCTreeSection(cellIdentifier: "NCTableViewHeaderCell", nodeIdentifier: String(attributeCategory.categoryID), title: sectionTitle.uppercased(), attributedTitle: nil, children: rows, configurationHandler: nil))
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
		return NCTreeSection(cellIdentifier: "NCTableViewHeaderCell", nodeIdentifier: String(NCDBAttributeCategoryID.requiredSkills.rawValue), title: nil, attributedTitle: title, children: rows, configurationHandler: nil)
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
		let unclaimedIcon = NCDBEveIcon.eveIcons(managedObjectContext: type.managedObjectContext!)["79_01"]
		var rows = [NCDatabaseTypeInfoRow]()
		for (key, array) in masteries.sorted(by: {return $0.key < $1.key}) {
			guard let level = array.first?.level else {continue}
			let trainingQueue = NCTrainingQueue(character: character)
			for mastery in array {
				trainingQueue.add(mastery: mastery)
			}
			let trainingTime = trainingQueue.trainingTime(characterAttributes: character.attributes)
			let title = NSLocalizedString("Mastery", comment: "") + " \(key + 1)"
			let subtitle = trainingTime > 0 ? NCTimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
			let icon = trainingTime > 0 ? unclaimedIcon : level.icon
			let row = NCDatabaseTypeInfoRow(title: title, subtitle: subtitle, image: icon?.image?.image, accessory: nil, object: level)
			rows.append(row)
		}
		
		if rows.count > 0 {
			return NCTreeSection(cellIdentifier: "NCTableViewHeaderCell", nodeIdentifier: "Mastery", title: NSLocalizedString("Mastery", comment: "").uppercased(), children: rows)
		}
		else {
			return nil
		}
	}
	
	/*class func marketHistory(history: [ESMarketHistory]) -> NCDatabaseTypeMarketRow? {
		guard history.count > 0 else {return nil}
		
		let range = history.suffix(90).indices
		
		let volume = UIBezierPath()
		volume.move(to: CGPoint(x: 0, y: 0))
		
		let donchian = UIBezierPath()
		let avg = UIBezierPath()
		
		var x: CGFloat = 0
		var isFirst = true
		
		var v = 0...0 as ClosedRange<Int>
		var p = 0...0 as ClosedRange<Double>
		let d = history[range.first!].date...history[range.last!].date
		
		for i in range {
			let item = history[i]
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
			volume.append(UIBezierPath(rect: CGRect(x: x - 0.5, y: 0, width: 1, height: CGFloat(item.volume))))
			donchian.append(UIBezierPath(rect: CGRect(x: x - 0.5, y: CGFloat(lowest.lowest), width: 1, height: abs(CGFloat(highest.highest - lowest.lowest)))))
			x += 1
			
			v = min(v.lowerBound, item.volume)...max(v.upperBound, item.volume)
			p = min(p.lowerBound, lowest.lowest)...max(p.upperBound, highest.highest)
		}
		
		donchian.close()
		
		return NCDatabaseTypeMarketRow(history: history, volume: volume, median: avg, donchian: donchian, date: d)
		
		/*var transform = CGAffineTransform.identity
		var rect = volume.bounds
		if rect.size.width > 0 && rect.size.height > 0 {
			transform = transform.scaledBy(x: 1, y: -1)
			transform = transform.translatedBy(x: 0, y: -bounds.size.height)
			transform = transform.scaledBy(x: bounds.size.width / rect.size.width, y: bounds.size.height / rect.size.height * 0.25)
			transform = transform.translatedBy(x: -rect.origin.x, y: -rect.origin.y)
			volume.apply(transform)
		}
		
		
		rect = donchian.bounds.union(avg.bounds)
		if rect.size.width > 0 && rect.size.height > 0 {
			transform = CGAffineTransform.identity
			transform = transform.scaledBy(x: 1, y: -1)
			transform = transform.translatedBy(x: 0, y: -bounds.size.height * 0.75)
			transform = transform.scaledBy(x: bounds.size.width / rect.size.width, y: bounds.size.height / rect.size.height * 0.75)
			transform = transform.translatedBy(x: -rect.origin.x, y: -rect.origin.y)
			donchian.apply(transform)
			avg.apply(transform)
		}
		
		UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
		UIBezierPath(rect: bounds).fill()
		UIColor.lightGray.setFill()
		donchian.fill()
		UIColor.blue.setFill()
		volume.fill()
		UIColor.orange.setStroke()
		avg.stroke()
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		if let image = image {
			return NCDatabaseTypeMarketRow(chartImage: image, history: history, volume: v, price: p, date: d)
		}
		else {
			return nil
		}*/
	}*/
}
