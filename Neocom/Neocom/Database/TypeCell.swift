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
                ShipCell(ship: type.dgmppItem!.shipResources!)
            }
            else {
                HStack {
                    Icon(type.image)
                    Text(type.typeName ?? "")
                }
            }
        }
    }
}

struct TypeCell_Previews: PreviewProvider {
    static var previews: some View {
        TypeCell(type: try! AppDelegate.sharedDelegate.storageContainer.viewContext.from(SDEInvType.self).filter(\SDEInvType.typeID == 645).first()!)
    }
}
