//
//  TypeInfoMasteryCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/5/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData

struct TypeInfoMasteryCell: View {
    var mastery: TypeInfoData.Row.Mastery
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var body: some View {
        HStack {
            mastery.image.map{Icon(Image(uiImage: $0))}
            VStack(alignment: .leading) {
                Text(mastery.title)
                mastery.subtitle.map{Text($0).modifier(SecondaryLabelModifier())}
            }
        }
    }
}

struct TypeInfoMasteryCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TypeInfoMasteryCell(mastery: TypeInfoData.Row.Mastery(id: NSManagedObjectID(),
                                                                  typeID: NSManagedObjectID(),
                                                                  title: "LEVEL II",
                                                                  subtitle: nil,
                                                                  image: (try? Storage.testStorage.persistentContainer.viewContext.fetch(SDEEveIcon.named(.mastery(1))).first?.image?.image) ?? UIImage()))
        }.listStyle(GroupedListStyle()).colorScheme(.light)
    }
}
