//
//  CoreData.swift
//  sde-tool
//
//  Created by Artem Shimanski on 20.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

public typealias UIImage = Data

extension TypeAttribute {
	var value: Float? {
		if let value = valueFloat {
			return Float(value)
		}
		else if let value = valueInt {
			return Float(value)
		}
		else {
			return nil
		}
	}
}

extension NCDBEveIcon {
	
	convenience init?(_ iconID: (key: Int, value: IconID)) {
		guard let range = iconID.value.iconFile.range(of: "res:/ui/texture/icons") else {return nil}
		let path = iconID.value.iconFile.replacingCharacters(in: range, with: "")
		let url = URL(fileURLWithPath: CommandLine.input).appendingPathComponent(path)
		guard let data = try? Data(contentsOf: url) else {return nil}
		self.init(context: context)
		iconFile = url.deletingPathExtension().lastPathComponent
		image = NCDBEveIconImage(context: context)
		image?.image = data
	}
	
	class func icon(iconName: String) -> NCDBEveIcon? {
		guard let icon = iconIDs.first(where: {$0.value.iconFile.hasSuffix("\(iconName).png")}) else {return nil}
		return .icon(iconID: icon.key)
	}
	
	class func icon(iconID: Int) -> NCDBEveIcon? {
		if let icon = eveIcons[iconID] {
			return icon
		}
		guard let icon = iconIDs[iconID] else {return nil}
		if let eveIcon = NCDBEveIcon((iconID, icon)) {
			eveIcons[iconID] = eveIcon
			return eveIcon
		}
		return nil
	}
	
	class func icon(typeID: Int) -> NCDBEveIcon? {
		let url = URL(fileURLWithPath: CommandLine.input).appendingPathComponent("Types/\(typeID)_64.png")
		guard let data = try? Data(contentsOf: url) else {return nil}
		let hash = data.hashValue
		if let icon = typeIcons[hash] {
			return icon
		}
		let icon = NCDBEveIcon(context: context)
		icon.image = NCDBEveIconImage(context: context)
		icon.image?.image = data
		typeIcons[hash] = icon
		return icon
	}

}


extension NCDBInvCategory {
	convenience init(_ category: (key: Int, value: CategoryID)) {
		self.init(context: context)
		categoryID = Int32(category.key)
		categoryName = category.value.name.en
		published = category.value.published
		if let iconID = category.value.iconID {
			icon = NCDBEveIcon.icon(iconID: iconID)
		}
	}
}

extension NCDBInvGroup {
	convenience init(_ group: (key: Int, value: GroupID)) {
		self.init(context: context)
		groupID = Int32(group.key)
		groupName = group.value.name.en
		published = group.value.published
		category = invCategories[group.value.categoryID]
		if let iconID = group.value.iconID {
			icon = NCDBEveIcon.icon(iconID: iconID)
		}
	}
}

extension NCDBInvType {
	convenience init(_ type: (key: Int, value: TypeID)) {
		self.init(context: context)
		typeID = Int32(type.key)
		typeName = type.value.name.en ?? ""
		basePrice = Float(type.value.basePrice ?? 0)
		capacity = Float(type.value.capacity ?? 0)
		mass = Float(type.value.mass ?? 0)
		radius = Float(type.value.radius ?? 0)
		volume = Float(type.value.volume ?? 0)
		published = type.value.published
		portionSize = Int32(type.value.portionSize)
		metaLevel = Int16(typeAttributes[type.key]?[NCDBDgmAttributeID.metaLevel.rawValue]?.value ?? 0)
		icon = .icon(typeID: type.key)
//		groupID = Int32(group.key)
//		groupName = group.value.name.en
//		published = group.value.published
//		category = invCategories[group.value.categoryID]
//		if let iconID = group.value.iconID {
//			icon = NCDBEveIcon.icon(iconID: iconID)
//		}
	}
}

extension NCDBInvMetaGroup {
	convenience init(_ metaGroup: MetaGroup) {
		self.init(context: context)
		metaGroupID = metaGroup.metaGroupID
		metaGroupName = metaGroup.metaGroupName
	}
}
