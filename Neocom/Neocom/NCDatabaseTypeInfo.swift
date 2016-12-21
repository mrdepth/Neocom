//
//  NCDatabaseTypeInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

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
	
	init(skill: NCDBInvTypeRequiredSkill, trainedLevel: Int?, children: [NCTreeNode]?) {
		self.title = "\(skill.skillType!.typeName!) \(skill.skillLevel)"
		//let eveIcons = NCDBEveIcon.eveIcons(managedObjectContext: skill.managedObjectContext!)
		//self.image = eveIcons["50_11"]?.image?.image
		self.accessory = nil
		if let trainedLevel = trainedLevel {
			let trained = trainedLevel >= Int(skill.skillLevel)
			self.image = UIImage(named: trained ? "skillRequirementMe" : "skillRequirementNotMe")
			//self.image = eveIcons[trainedLevel >= Int(skill.skillLevel) ? "38_193" : "38_195"]?.image?.image
			self.tintColor = trained ? UIColor.caption : UIColor.lightGray
		}
		else {
			//self.image = eveIcons["38_194"]?.image?.image
			self.image = UIImage(named: "skillRequirementNotInjected")
			self.tintColor = UIColor.lightGray
		}
		self.object = skill.skillType
		
		super.init(cellIdentifier: "Cell", nodeIdentifier: nil, children: children)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCDefaultTableViewCell
		cell.titleLabel?.text = title
		cell.subtitleLabel?.text = nil
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
		shipInfo(type: type, completionHandler: completionHandler)
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
					let trainedSkill = character.skills[Int(type.typeID)]
					let row = NCDatabaseTypeSkillRow(skill: requiredSkill, trainedLevel: trainedSkill?.level, children: subskills(skill: type))
					rows.append(row)
				}
				return rows
			}
			
			let trainedSkill = character.skills[Int(type.typeID)]
			let row = NCDatabaseTypeSkillRow(skill: requiredSkill, trainedLevel: trainedSkill?.level, children: subskills(skill: type))
			rows.append(row)
		}
		return NCTreeSection(cellIdentifier: "NCTableViewHeaderCell", nodeIdentifier: String(NCDBAttributeCategoryID.requiredSkills.rawValue), title: NSLocalizedString("Required Skills", comment: ""), attributedTitle: nil, children: rows, configurationHandler: nil)
	}
}
