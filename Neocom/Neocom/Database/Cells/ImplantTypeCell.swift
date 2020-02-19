//
//  ImplantTypeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/21/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct ImplantTypeCell: View {
    var implant: SDEInvType
    
    private static let attributes = [(SDEAttributeID.intelligenceBonus, Text("Intelligence")),
                                     (SDEAttributeID.memoryBonus, Text("Memory")),
                                     (SDEAttributeID.perceptionBonus, Text("Perception")),
                                     (SDEAttributeID.willpowerBonus, Text("Willpower")),
                                     (SDEAttributeID.charismaBonus, Text("Charisma"))]
    private func attribute() -> Text? {
        let bonuses = ImplantTypeCell.attributes.compactMap { i in
            self.implant[i.0].flatMap { attribute in
                attribute.value > 0 ? i.1 + Text(" +\(Int(attribute.value))") : nil
            }
        }
        if let first = bonuses.first {
            return bonuses[1...].reduce(first, {$0 + Text(", ") + $1})
        }
        else {
            return nil
        }
//
//        return ImplantTypeCell.attributes.lazy
//            .compactMap{i in self.implant[i.key].map{(title: i.value, value: $0.value)}}
//            .first{i in i.value > 0}
//            .map { attribute -> Text in
//                attribute.title + Text(" +\(Int(attribute.value))")
//        }
    }

    
    var body: some View {
        NavigationLink(destination: TypeInfo(type: implant)) {
            HStack {
                Icon(implant.image).cornerRadius(4)
                VStack(alignment: .leading) {
                    Text(implant.typeName ?? "")
                    attribute()?.modifier(SecondaryLabelModifier())
                }
            }
        }
    }
}

struct ImplantTypeCell_Previews: PreviewProvider {
    static var previews: some View {
        let implant = try? AppDelegate.sharedDelegate.persistentContainer.viewContext
            .from(SDEInvType.self)
            .filter(Expressions.keyPath(\SDEInvType.attributes).subquery(Expressions.keyPath(\SDEDgmTypeAttribute.attributeType?.attributeID) == SDEAttributeID.intelligenceBonus.rawValue).count > 0)
            .first()
        
        return List {
            ImplantTypeCell(implant: implant!)
        }.listStyle(GroupedListStyle())
    }
}
