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
	dynamic var title: String?
	dynamic var subtitle: String?
	dynamic var image: UIImage?
	dynamic var accessory: UIImage?
	dynamic var object: Any?
	
	init(title: String?, subtitle: String?, image: UIImage?, accessory: UIImage?, object: Any?) {
		self.title = title
		self.subtitle = subtitle
		self.image = image
		self.accessory = accessory
		self.object = object
		super.init(cellIdentifier: "Cell")
	}

}

class NCDatabaseTypeSkillRow: NCTreeSection {
}

class NCDatabaseTypeInfo {
	
	class func typeInfo(typeID: NSManagedObjectID, completionHandler: @escaping ([NCTreeSection]) -> Void) {
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
					
					switch NCDBUnitID(rawValue: Int(attributeType.unit?.unitID ?? 0)) ?? NCDBUnitID.none {
					case .typeID:
						let typeID = Int(attribute.value)
						guard let requiredSkills = type.requiredSkills?.array as? [NCDBInvTypeRequiredSkill] else {continue}
						guard let skill = requiredSkills.first (where: {Int($0.type!.typeID) == typeID}) else {continue}
						guard let type = skill.type else {continue}
						
						func subskills(skill: NCDBInvType) -> [NCDatabaseTypeSkillRow] {
							var rows = [NCDatabaseTypeSkillRow]()
							for requiredSkill in skill.requiredSkills ?? [] {
								if let requiredSkill = requiredSkill as? NCDBInvTypeRequiredSkill, let type = requiredSkill.type {
									let row = NCDatabaseTypeSkillRow(cellIdentifier: "Cell", nodeIdentifier: nil, children: subskills(skill: type))
									rows.append(row)
								}
							}
							return rows
						}
						
						let row = NCDatabaseTypeSkillRow(cellIdentifier: "Cell", nodeIdentifier: nil, children: subskills(skill: type))
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
					default:
						break
					}
					
					if let unitID = attributeType.unit?.unitID, Int(unitID) == NCDBUnitID.typeID.rawValue {
					}
				}
			}
		})
	}
}
