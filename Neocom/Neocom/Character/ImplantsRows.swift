//
//  ImplantsRows.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/21/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct ImplantsRows: View {
    var implants: [Int]
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        let implants = self.implants.compactMap { try? self.managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32($0)).first() }
            .map {(type: $0, slot: $0[SDEAttributeID.implantness]?.value ?? 100)}
            .sorted{$0.slot < $1.slot}
            .map{$0.type}

        return Group {
            if implants.isEmpty {
                Text("No Implants").foregroundColor(.secondary).frame(maxWidth: .infinity)
            }
            else {
                ForEach(implants, id: \.objectID) { i in
                    ImplantTypeCell(implant: i)
                }
            }
        }
    }
}

struct ImplantsRows_Previews: PreviewProvider {
    static var previews: some View {
        let implant = try? Storage.testStorage.persistentContainer.viewContext
            .from(SDEInvType.self)
            .filter((/\SDEInvType.attributes).subquery(/\SDEDgmTypeAttribute.attributeType?.attributeID == SDEAttributeID.intelligenceBonus.rawValue).count > 0)
            .first()

        return List {
            Section(header: Text("IMPLANTS")) {
                ImplantsRows(implants: [Int(implant!.typeID)])
            }
        }.listStyle(GroupedListStyle())
        .modifier(ServicesViewModifier.testModifier())
    }
}
