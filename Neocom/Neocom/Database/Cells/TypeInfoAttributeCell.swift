//
//  TypeInfoAttributeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/3/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TypeInfoAttributeCell: View {
    var attribute: SDEDgmTypeAttribute
    
    private var title: String {
        if let displayName = attribute.attributeType?.displayName, !displayName.isEmpty {
            return displayName
        }
        else if let attributeName = attribute.attributeType?.attributeName, !attributeName.isEmpty {
            return attributeName
        }
        else {
            return "\(attribute.attributeType?.attributeID ?? 0)"
        }
    }
    
    private var subtitle: String {
        func toString(_ value: Double) -> String {
            var s = UnitFormatter.localizedString(from: value, unit: .none, style: .long)
            if let unit = attribute.attributeType?.unit?.displayName {
                s += " " + unit
            }
            return s
        }
        
        
        let value = attribute.value
        
        switch unitID {
//        case .attributeID:
//            let attributeType = context.dgmAttributeType(Int(value))
//            return attributeType?.displayName ?? attributeType?.attributeName
//        case .groupID:
//            let group = context.invGroup(Int(value))
//            return group?.groupName
//            icon = attribute.attributeType?.icon ?? group?.icon
//            route = group.map{Router.SDE.invTypes(.group($0))}
//        case .typeID:
//            let type = context.invType(Int(value))
//            subtitle = type?.typeName
//            icon = type?.icon ?? attribute.attributeType?.icon
//            route = Router.SDE.invTypeInfo(.typeID(Int(value)))
        case .sizeClass:
            return SDERigSize(rawValue: Int(value))?.description ?? String(describing: Int(value))
        case .bonus:
            return "+" + UnitFormatter.localizedString(from: value, unit: .none, style: .long)
//            icon = attribute.attributeType?.icon
        case .boolean:
            return Int(value) == 0 ? NSLocalizedString("No", comment: "") : NSLocalizedString("Yes", comment: "")
        case .inverseAbsolutePercent, .inversedModifierPercent:
            return toString((1.0 - value) * 100.0)
        case .modifierPercent:
            return toString((value - 1.0) * 100.0)
        case .absolutePercent:
            return toString(value * 100.0)
        case .milliseconds:
            return toString(value / 1000.0)
        default:
            return toString(value)
        }
    }
    
    private var unitID: SDEUnitID {
        (attribute.attributeType?.unit?.unitID).flatMap {SDEUnitID(rawValue: $0)} ?? .none
    }
    
    private var icon: UIImage? {
        switch unitID {
            //        case .attributeID:
            //            let attributeType = context.dgmAttributeType(Int(value))
            //            return attributeType?.displayName ?? attributeType?.attributeName
            //        case .groupID:
            //            let group = context.invGroup(Int(value))
            //            return group?.groupName
            //            icon = attribute.attributeType?.icon ?? group?.icon
            //            route = group.map{Router.SDE.invTypes(.group($0))}
            //        case .typeID:
            //            let type = context.invType(Int(value))
            //            subtitle = type?.typeName
            //            icon = type?.icon ?? attribute.attributeType?.icon
        //            route = Router.SDE.invTypeInfo(.typeID(Int(value)))
        default:
            return attribute.attributeType?.icon?.image?.image
        }
    }
    
    var body: some View {
        HStack {
            icon.map{Icon(Image(uiImage: $0))}
            VStack(alignment: .leading) {
                Text(title.uppercased()).font(.footnote)
                Text(subtitle).font(.footnote).foregroundColor(.secondary)
            }
        }
    }
}

struct TypeInfoAttributeCell_Previews: PreviewProvider {
    static var previews: some View {
        var attributes = (try? AppDelegate.sharedDelegate.testingContainer.viewContext.fetch(SDEInvType.dominix()).first?.attributes?.allObjects as? [SDEDgmTypeAttribute]) ?? []
        attributes.sort{$0.attributeType!.attributeName! < $1.attributeType!.attributeName!}
        return List(attributes, id: \.objectID) { attribute in
            TypeInfoAttributeCell(attribute: attribute)
        }.listStyle(GroupedListStyle())
    }
}
