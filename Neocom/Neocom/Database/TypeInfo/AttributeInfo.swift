//
//  AttributeInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/31/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct AttributeInfo: View {
    var attribute: SDEDgmTypeAttribute
    var attributeValues: [Int: Double]?
    
    private static let skipAttributeIDs: Set<SDEAttributeID> = {
        Set((damageResonanceAttributes + damageAttributes).flatMap{$0.filter{$0.key != .em}}.map{$0.value})
    }()
    
    private static let damageAttributeIDs: Set<SDEAttributeID> = {
        Set((damageResonanceAttributes + damageAttributes).flatMap{$0.filter{$0.key == .em}}.map{$0.value})
    }()

    private func cell(title: LocalizedStringKey, subtitle: String?, image: UIImage?) -> some View {
        HStack {
            image.map{Icon(Image(uiImage: $0)).cornerRadius(4)}
            VStack(alignment: .leading) {
                Text(title)
                subtitle.map{Text($0).modifier(SecondaryLabelModifier())}
            }
        }
    }

    private func warpSpeed() -> some View {
        let attributeType = attribute.attributeType!
        let value = attributeValues?[Int(attributeType.attributeID)] ?? attribute.value
        let type = attribute.type
        
        let baseWarpSpeed = attributeValues?[Int(SDEAttributeID.baseWarpSpeed.rawValue)] ?? type?[SDEAttributeID.baseWarpSpeed]?.value ?? 1.0
        var s = UnitFormatter.localizedString(from: Double(value * baseWarpSpeed), unit: .none, style: .long)
        s += " " + NSLocalizedString("AU/sec", comment: "")
        return cell(title: "Warp Speed", subtitle: s, image: attributeType.icon?.image?.image)
    }

    private func damageInfo() -> TypeInfoDamageCell {
        let attributeID = (attribute.attributeType?.attributeID).flatMap{SDEAttributeID(rawValue:$0)}
        let type = attribute.type

        func damage(from attributes: [DamageType: SDEAttributeID]) -> Damage {
            func get(_ damageType: DamageType) -> Double {
                attributes[damageType].flatMap{attributeValues?[Int($0.rawValue)] ?? type?[$0]?.value} ?? 0
            }
            return Damage(em: get(.em), thermal: get(.thermal), kinetic: get(.kinetic), explosive: get(.explosive))
        }
        
        if let attributes = damageAttributes.first(where: {$0[.em] == attributeID}) {
            return TypeInfoDamageCell(damage: damage(from: attributes), percentStyle: false)
            
        }
        else if let attributes = damageResonanceAttributes.first(where: {$0[.em] == attributeID}) {
            return TypeInfoDamageCell(damage: damage(from: attributes), percentStyle: true)
        }
        else {
            return TypeInfoDamageCell(damage: Damage(), percentStyle: false)
        }
    }
    
    
    var body: some View {
        let attributeID = (attribute.attributeType?.attributeID).flatMap{SDEAttributeID(rawValue:$0)}
        return Group {
            if attributeID != nil {
                if !Self.skipAttributeIDs.contains(attributeID!) {
                    if Self.damageAttributeIDs.contains(attributeID!) {
                        damageInfo()
                    }
                    else if attributeID! == .warpSpeedMultiplier {
                        warpSpeed()
                    }
                    else {
                        TypeInfoAttributeCell(attribute: attribute)
                    }
                }
            }
            else {
                TypeInfoAttributeCell(attribute: attribute)
            }
        }
    }
}

struct AttributeInfo_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ForEach((SDEInvType.dominix.attributes?.allObjects as? [SDEDgmTypeAttribute])!, id: \.objectID) {
                AttributeInfo(attribute: $0)
            }
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        
    }
}
