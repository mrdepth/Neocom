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
    private var title: Text
    private var subtitle: Text?
    private var icon: Icon?
    private var targetType: SDEInvType?
    private var targetGroup: SDEInvGroup?

    init(attribute: SDEDgmTypeAttribute, value: Double? = nil) {
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
        
        
        let value = value ?? attribute.value
        var targetType: SDEInvType?
        var targetGroup: SDEInvGroup?
        
        switch unitID {
        case .attributeID:
            let attributeType = try? attribute.managedObjectContext?.from(SDEDgmAttributeType.self)
                .filter(Expressions.keyPath(\SDEDgmAttributeType.attributeID) == Int32(value)).first()
            icon = attributeType?.icon?.image?.image
            subtitle = attributeType?.displayName ?? attributeType?.attributeName ?? toString(value)
        case .groupID:
            let group = try? attribute.managedObjectContext?.from(SDEInvGroup.self)
                .filter(Expressions.keyPath(\SDEInvGroup.groupID) == Int32(value)).first()
            subtitle = group?.groupName ?? toString(value)
            icon = attribute.attributeType?.icon?.image?.image ?? group?.icon?.image?.image
            targetGroup = group
        case .typeID:
            let type = try? attribute.managedObjectContext?.from(SDEInvType.self)
                .filter(Expressions.keyPath(\SDEInvType.typeID) == Int32(value)).first()
            subtitle = type?.typeName ?? toString(value)
            icon = type?.icon?.image?.image ?? attribute.attributeType?.icon?.image?.image
            targetType = type
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
        
        self.title = Text(title)
        self.subtitle = Text(subtitle)
        self.icon = image.map{Icon(Image(uiImage: $0))}
        self.targetType = targetType
        self.targetGroup = targetGroup
    }
    
    init(title: Text, subtitle: Text? = nil, image: Image? = nil, targetType: SDEInvType? = nil, targetGroup: SDEInvGroup? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = image.map{Icon($0)}
        self.targetType = targetType
        self.targetGroup = targetGroup
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var body: some View {
        let content = HStack {
            icon.cornerRadius(4)
            VStack(alignment: .leading) {
                title
                subtitle?.modifier(SecondaryLabelModifier())
            }
        }
        
        return Group {
            if targetType != nil {
                NavigationLink(destination: TypeInfo(type: targetType!)) { content }
            }
            else if targetGroup != nil {
                NavigationLink(destination: Types(.group(targetGroup!))) { content }
            }
            else {
                content
            }
        }
    }
}

struct TypeInfoAttributeCell_Previews: PreviewProvider {
    static var previews: some View {
        var attributes = (SDEInvType.dominix.attributes?.allObjects as? [SDEDgmTypeAttribute]) ?? []
        attributes.sort{$0.attributeType!.attributeName! < $1.attributeType!.attributeName!}
        return NavigationView {
            List(attributes, id: \.objectID) { row in
                TypeInfoAttributeCell(attribute: row)
            }.listStyle(GroupedListStyle())
        }
    }
}
