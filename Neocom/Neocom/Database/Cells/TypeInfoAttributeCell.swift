//
//  TypeInfoAttributeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/3/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible

extension TypeInfoData.Row {
    var attribute: Attribute? {
        switch self {
        case let .attribute(attribute):
            return attribute
        default:
            return nil
        }
    }
}

struct TypeInfoAttributeCell: View {
    var attribute: SDEDgmTypeAttribute
    var value: Double?
    
    @Environment(\.managedObjectContext) var managedObjectContext
    
    private func content(title: String, subtitle: String, image: UIImage?) -> some View {
        HStack {
            image.map{Icon(Image(uiImage: $0))}
            VStack(alignment: .leading) {
                Text(title.uppercased()).font(.footnote)
                Text(subtitle).font(.footnote).foregroundColor(.secondary)
            }
        }
    }

    var body: some View {
        let title: String
        
        if let displayName = attribute.attributeType?.displayName, !displayName.isEmpty {
            title = displayName
        }
        else if let attributeName = attribute.attributeType?.attributeName, !attributeName.isEmpty {
            title = attributeName
        }
        else {
            title = "\(attribute.attributeType?.attributeID ?? 0)"
        }

        
        let unitID = (attribute.attributeType?.unit?.unitID).flatMap {SDEUnitID(rawValue: $0)} ?? .none
        var icon: UIImage?
        
        let subtitle: String
        
        func toString(_ value: Double) -> String {
            var s = UnitFormatter.localizedString(from: value, unit: .none, style: .long)
            if let unit = attribute.attributeType?.unit?.displayName {
                s += " " + unit
            }
            return s
        }
        
        
        let value = self.value ?? attribute.value
        var targetType: NSManagedObjectID?
        var targetGroup: NSManagedObjectID?
        
        switch unitID {
        case .attributeID:
            let attributeType = try? attribute.managedObjectContext?.from(SDEDgmAttributeType.self)
                .filter(\SDEDgmAttributeType.attributeID == Int(value)).first()
            icon = attributeType?.icon?.image?.image
            subtitle = attributeType?.displayName ?? attributeType?.attributeName ?? toString(value)
        case .groupID:
            let group = try? attribute.managedObjectContext?.from(SDEInvGroup.self)
                .filter(\SDEInvGroup.groupID == Int(value)).first()
            subtitle = group?.groupName ?? toString(value)
            icon = attribute.attributeType?.icon?.image?.image ?? group?.icon?.image?.image
            targetGroup = group?.objectID
        case .typeID:
            let type = try? attribute.managedObjectContext?.from(SDEInvType.self)
                .filter(\SDEInvType.typeID == Int(value)).first()
            subtitle = type?.typeName ?? toString(value)
            icon = type?.icon?.image?.image ?? attribute.attributeType?.icon?.image?.image
            targetType = type?.objectID
        case .sizeClass:
            subtitle = SDERigSize(rawValue: Int(value))?.description ?? String(describing: Int(value))
        case .bonus:
            subtitle = "+" + UnitFormatter.localizedString(from: value, unit: .none, style: .long)
        case .boolean:
            subtitle = Int(value) == 0 ? NSLocalizedString("No", comment: "") : NSLocalizedString("Yes", comment: "")
        case .inverseAbsolutePercent, .inversedModifierPercent:
            subtitle = toString((1.0 - value) * 100.0)
        case .modifierPercent:
            subtitle = toString((value - 1.0) * 100.0)
        case .absolutePercent:
            subtitle = toString(value * 100.0)
        case .milliseconds:
            subtitle = toString(value / 1000.0)
        default:
            subtitle = toString(value)
        }
        
        let image = icon ?? attribute.attributeType?.icon?.image?.image
        return Group {
            if targetType != nil {
                NavigationLink(destination: TypeInfo(type: managedObjectContext.object(with: targetType!) as! SDEInvType)) { content(title: title, subtitle: subtitle, image: image) }
            }
            else if targetGroup != nil {
                NavigationLink(destination: Types(.group(managedObjectContext.object(with: targetGroup!) as! SDEInvGroup))) { content(title: title, subtitle: subtitle, image: image) }
            }
            else {
                content(title: title, subtitle: subtitle, image: image)
            }
        }
    }
}

struct TypeInfoAttributeCell_Previews: PreviewProvider {
    static var previews: some View {
        var attributes = (try? AppDelegate.sharedDelegate.testingContainer.viewContext.fetch(SDEInvType.dominix()).first?.attributes?.allObjects as? [SDEDgmTypeAttribute]) ?? []
        attributes.sort{$0.attributeType!.attributeName! < $1.attributeType!.attributeName!}
        return NavigationView {
            List(attributes, id: \.objectID) { row in
                TypeInfoAttributeCell(attribute: row)
            }.listStyle(GroupedListStyle())
        }
    }
}
