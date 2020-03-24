//
//  ChargeTypeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/28/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import Dgmpp

struct ChargeTypeCell: View {
    var charge: SDEDgmppItemDamage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Icon(charge.item!.type!.image).cornerRadius(4)
                Text(charge.item?.type?.typeName ?? "")
            }
            DamageVectorView(damage: DGMDamageVector(charge))
        }
    }
}

struct ChargeTypeCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ChargeTypeCell(charge: (try! AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEInvType.self).filter(/\SDEInvType.dgmppItem?.damage != nil).first()?.dgmppItem?.damage)!)
        }.listStyle(GroupedListStyle())
    }
}
