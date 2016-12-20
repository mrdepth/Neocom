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
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCTableViewDefaultCell
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
	
	init(skill: NCDBInvTypeRequiredSkill, trainedLevel: Int?, children: [NCTreeNode]?) {
		self.title = "\(skill.skillType!.typeName!) \(skill.skillLevel)"
		let eveIcons = NCDBEveIcon.eveIcons(managedObjectContext: skill.managedObjectContext!)
		self.image = eveIcons["50_11"]?.image?.image
		if let trainedLevel = trainedLevel {
			self.accessory = eveIcons[trainedLevel >= Int(skill.skillLevel) ? "38_193" : "38_195"]?.image?.image
		}
		else {
			self.accessory = eveIcons["38_194"]?.image?.image
		}
		self.object = skill.skillType
		super.init(cellIdentifier: "Cell", nodeIdentifier: nil, children: children)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCTableViewDefaultCell
		cell.titleLabel?.text = title
		cell.subtitleLabel?.text = nil
		cell.iconView?.image = image
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

class NCDatabaseTypeInfo {
	
	class func typeInfo(typeID: NSManagedObjectID, completionHandler: @escaping ([NCTreeSection]) -> Void) {
		let account = NCAccount.current
		var skillLevels = [Int: Int]()
		
		
		func load() {
			NCDatabase.sharedDatabase?.performBackgroundTask({ (managedObjectContext) in
				var sections = [NCTreeSection]()
				
				defer {
					DispatchQueue.main.async {
						completionHandler(sections)
					}
				}
				
				guard let type = (try? managedObjectContext.existingObject(with: typeID)) as? NCDBInvType else {return}
				
				let request = NSFetchRequest<NCDBDgmTypeAttribute>(entityName: "DgmTypeAttribute")
				request.predicate = NSPredicate(format: "type == %@ AND attributeType.published == TRUE", type)
				request.sortDescriptors = [NSSortDescriptor(key: "attributeType.attributeCategory.categoryName", ascending: true), NSSortDescriptor(key: "attributeType.displayName", ascending: true)]
				let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "attributeType.attributeCategory.categoryName", cacheName: nil)
				guard let _ = try? results.performFetch() else {return}
				guard results.sections != nil else {return}
				
				for section in results.sections! {
					guard let attributeCategory = (section.objects?.first as? NCDBDgmTypeAttribute)?.attributeType?.attributeCategory else {continue}
					let sectionTitle: String
					if Int(attributeCategory.categoryID) == NCDBAttributeCategoryID.null.rawValue {
						sectionTitle = NSLocalizedString("Other", comment: "")
					}
					else {
						sectionTitle = attributeCategory.categoryName ?? NSLocalizedString("Other", comment: "")
					}
					
					var rows = [NCTreeNode]()
					
					for attribute in (section.objects as? [NCDBDgmTypeAttribute]) ?? [] {
						guard let attributeType = attribute.attributeType else {continue}
						let title: String
						if let displayName = attributeType.displayName, !displayName.isEmpty {
							title = displayName
						}
						else if let attributeName = attributeType.attributeName, !attributeName.isEmpty {
							title = attributeName
						}
						else {
							continue
						}
						
						if Int(attributeType.attributeID) == NCDBAttributeID.warpSpeedMultiplier.rawValue {
							let baseWarpSpeed = type.allAttributes[NCDBAttributeID.baseWarpSpeed.rawValue]?.value ?? 1.0
							var s = NCUnitFormatter.localizedString(from: Double(attribute.value * baseWarpSpeed), unit: .none, style: .full)
							s += " " + NSLocalizedString("AU/sec", comment: "")
							rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: s, image: attributeType.icon?.image?.image, accessory: nil, object: nil))
							continue
						}
						
						func toString(_ value: Float, _ unit: String?) -> String {
							var s = NCUnitFormatter.localizedString(from: Double(value), unit: .none, style: .full)
							if let unit = unit {
								s += " " + unit
							}
							return s
						}
						
						switch NCDBUnitID(rawValue: Int(attributeType.unit?.unitID ?? 0)) ?? NCDBUnitID.none {
						case .typeID:
							let typeID = Int(attribute.value)
							guard let requiredSkills = type.requiredSkills?.array as? [NCDBInvTypeRequiredSkill] else {continue}
							guard let skill = requiredSkills.first (where: {Int($0.skillType!.typeID) == typeID}) else {continue}
							guard let type = skill.skillType else {continue}
							
							func subskills(skill: NCDBInvType) -> [NCDatabaseTypeSkillRow] {
								var rows = [NCDatabaseTypeSkillRow]()
								for requiredSkill in skill.requiredSkills ?? [] {
									if let requiredSkill = requiredSkill as? NCDBInvTypeRequiredSkill, let type = requiredSkill.skillType {
										let row = NCDatabaseTypeSkillRow(skill: requiredSkill, trainedLevel: skillLevels[Int(requiredSkill.skillType!.typeID)], children: subskills(skill: type))
										rows.append(row)
									}
								}
								return rows
							}
							
							let row = NCDatabaseTypeSkillRow(skill: skill, trainedLevel: skillLevels[Int(skill.skillType!.typeID)], children: subskills(skill: type))
							rows.append(row)
							
						case .attributeID:
							guard let attributeType = NCDBDgmAttributeType.dgmAttributeTypes(managedObjectContext: managedObjectContext)[Int(attribute.value)] else {break}
							rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: attributeType.displayName ?? attributeType.attributeName ?? "", image: attributeType.icon?.image?.image, accessory: nil, object: nil))
							
						case .groupID:
							guard let group = NCDBInvGroup.invGroups(managedObjectContext: managedObjectContext)[Int(attribute.value)] else {break}
							let image = attributeType.icon?.image?.image ?? group.icon?.image?.image
							rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: group.groupName ?? "", image: image, accessory: nil, object: group.objectID))
							break
						case .sizeClass:
							let sizeClass: String
							switch Int(attribute.value) {
							case 1:
								sizeClass = NSLocalizedString("Small", comment: "")
							case 2:
								sizeClass = NSLocalizedString("Medium", comment: "")
							default:
								sizeClass = NSLocalizedString("Large", comment: "")
							}
							rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: sizeClass, image: attributeType.icon?.image?.image, accessory: nil, object: nil))
						case .bonus:
							let bonus = "+" + NCUnitFormatter.localizedString(from: Double(attribute.value), unit: .none, style: .full)
							rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: bonus, image: attributeType.icon?.image?.image, accessory: nil, object: nil))
						case .boolean:
							let boolean = Int(attribute.value) == 0 ? NSLocalizedString("No", comment: "") : NSLocalizedString("Yes", comment: "")
							rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: boolean, image: attributeType.icon?.image?.image, accessory: nil, object: nil))
						case .inverseAbsolutePercent, .inversedModifierPercent:
							let s = toString((1.0 - attribute.value) * 100.0, attributeType.unit?.displayName)
							rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: s, image: attributeType.icon?.image?.image, accessory: nil, object: nil))
						case .modifierPercent:
							let s = toString((attribute.value - 1.0) * 100.0, attributeType.unit?.displayName)
							rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: s, image: attributeType.icon?.image?.image, accessory: nil, object: nil))
						case .absolutePercent:
							let s = toString(attribute.value * 100.0, attributeType.unit?.displayName)
							rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: s, image: attributeType.icon?.image?.image, accessory: nil, object: nil))
						case .milliseconds:
							let s = toString(attribute.value / 1000.0, attributeType.unit?.displayName)
							rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: s, image: attributeType.icon?.image?.image, accessory: nil, object: nil))
						default:
							let s = toString(attribute.value, attributeType.unit?.displayName)
							rows.append(NCDatabaseTypeInfoRow(title: title, subtitle: s, image: attributeType.icon?.image?.image, accessory: nil, object: nil))
						}
					}
					if rows.count > 0 {
						
						sections.append(NCTreeSection(cellIdentifier: "NCTableViewHeaderCell", nodeIdentifier: String(attributeCategory.categoryID), title: sectionTitle.uppercased(), attributedTitle: nil, children: rows, configurationHandler: nil))
					}
				}
			})
		}
		
		if let account = account {
			NCDataManager.init(account: account, cachePolicy: .returnCacheDataElseLoad).skills { result in
				switch result {
				case let .success(value: value, cacheRecordID: _):
					for skill in value.skills {
						skillLevels[skill.skillID] = skill.currentSkillLevel
					}
				case .failure:
					break
				}
				load()
			}
		}
		else {
			load()
		}
	}
}
