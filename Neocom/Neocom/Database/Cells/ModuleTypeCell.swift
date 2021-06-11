//
//  ModuleTypeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/28/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct ModuleTypeCell: View {
    var module: SDEDgmppItemRequirements
    
    private func column(_ image: String, _ value: Float, _ unit: UnitFormatter.Unit) -> some View {
        return value > 0 ? HStack(spacing: 0) {
            Icon(Image(image), size: .small)
            Text("\(UnitFormatter.localizedString(from: value, unit: unit, style: .long))")
            } : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Icon(module.item!.type!.image).cornerRadius(4)
                Text(module.item?.type?.typeName ?? "")
            }
            HStack(spacing: 15) {
                column("powerGrid", module.powerGrid, .megaWatts)
                column("cpu", module.cpu, .teraflops)
                column("calibration", module.calibration, .none)
            }.modifier(SecondaryLabelModifier())
        }
    }
}

#if DEBUG
struct ModuleTypeCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ModuleTypeCell(module: (try! Storage.testStorage.persistentContainer.viewContext.from(SDEInvType.self).filter(/\SDEInvType.dgmppItem?.requirements?.powerGrid > 10000).first()?.dgmppItem?.requirements)!)
            ModuleTypeCell(module: (try! Storage.testStorage.persistentContainer.viewContext.from(SDEInvType.self).filter(/\SDEInvType.dgmppItem?.requirements?.calibration > 0).first()?.dgmppItem?.requirements)!)
        }.listStyle(GroupedListStyle())
    }
}
#endif
