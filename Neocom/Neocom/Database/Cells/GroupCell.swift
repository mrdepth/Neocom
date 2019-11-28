//
//  GroupCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/28/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible

struct GroupCell: View {
    var group: SDEInvGroup
    var body: some View {
        HStack {
            Icon(group.image).cornerRadius(4)
            Text(group.groupName ?? "")
        }
    }
}

struct GroupCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            GroupCell(group: (try! AppDelegate.sharedDelegate.storageContainer.viewContext.fetch(SDEInvType.dominix()).first?.group)!)
        }.listStyle(GroupedListStyle())
    }
}
