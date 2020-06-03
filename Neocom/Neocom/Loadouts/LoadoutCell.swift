//
//  LoadoutCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/20/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible

struct LoadoutCell: View {
    var typeID: Int
    var name: String?
//    var loadoutID: NSManagedObjectID
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(typeID)).first()
        
        return HStack {
            type.map{Icon($0.image).cornerRadius(4)}
            VStack(alignment: .leading) {
                type?.typeName.map{Text($0)} ?? Text("Unknown")
                if name?.isEmpty == false {
                    name.map{Text($0).modifier(SecondaryLabelModifier())}
                }
            }
        }
    }
}

struct LoadoutCell_Previews: PreviewProvider {
    static var previews: some View {
        let loadout = Loadout(context: Storage.sharedStorage.persistentContainer.viewContext)
        loadout.name = "Test Loadout"
        loadout.typeID = 645
        
        return List {
            LoadoutCell(typeID: 645, name: "Test Loadout")
        }.listStyle(GroupedListStyle())
            .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
