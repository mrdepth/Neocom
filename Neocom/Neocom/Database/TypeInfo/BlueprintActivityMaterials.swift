//
//  BlueprintActivityMaterials.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/27/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct BlueprintActivityMaterials: View {

    
    var activity: SDEIndActivity
    var body: some View {
        let materials = (activity.requiredMaterials?.allObjects as? [SDEIndRequiredMaterial])?.filter {$0.materialType?.typeName != nil}.sorted {$0.materialType!.typeName! < $1.materialType!.typeName!} ?? []

        return List(materials, id: \.objectID) { material in
            TypeInfoAttributeCell(title: Text(material.materialType?.typeName ?? ""),
                                  subtitle: Text("x\(material.quantity)"),
                                  image: material.materialType?.image, targetType: material.materialType)
        }.listStyle(GroupedListStyle()).navigationBarTitle(Text("Materials"))
    }
}

#if DEBUG
struct BlueprintActivityMaterials_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BlueprintActivityMaterials(activity: try! Storage.testStorage.persistentContainer.viewContext.from(SDEIndActivity.self).first()!)
        }
    }
}
#endif
