//
//  TypeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/27/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct TypeCell: View {
    var type: SDEInvType
    var body: some View {
        Group {
            if type.dgmppItem?.shipResources != nil {
                ShipTypeCell(ship: type.dgmppItem!.shipResources!)
            }
            else if type.dgmppItem?.requirements != nil {
                ModuleTypeCell(module: type.dgmppItem!.requirements!)
            }
            else if type.dgmppItem?.damage != nil {
                ChargeTypeCell(charge: type.dgmppItem!.damage!)
            }
            else {
                HStack {
                    Icon(type.image).cornerRadius(4)
                    Text(type.typeName ?? "")
                }
            }
        }
    }
}

struct TypeCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TypeCell(type: (try! AppDelegate.sharedDelegate.storageContainer.viewContext.fetch(SDEInvType.dominix()).first)!)
            TypeCell(type: (try! AppDelegate.sharedDelegate.storageContainer.viewContext.from(SDEInvType.self).filter(\SDEInvType.dgmppItem?.requirements?.powerGrid > 10000).first())!)
            TypeCell(type: (try! AppDelegate.sharedDelegate.storageContainer.viewContext.from(SDEInvType.self).filter(\SDEInvType.dgmppItem?.damage != nil).first())!)

        }.listStyle(GroupedListStyle())
    }
}
