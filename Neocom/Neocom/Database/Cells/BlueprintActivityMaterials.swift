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
            NavigationLink(destination: TypeInfo(type: material.materialType!)) {
                HStack {
                    material.materialType.map{Icon($0.image).cornerRadius(4)}
                    VStack(alignment: .leading) {
                        Text(material.materialType?.typeName ?? "")
                        Text("x\(material.quantity)").font(.footnote).foregroundColor(.secondary)
                    }
                }
            }
        }.listStyle(GroupedListStyle()).navigationBarTitle("Materials")
    }
}

struct BlueprintActivityMaterials_Previews: PreviewProvider {
    static var previews: some View {
        BlueprintActivityMaterials(activity: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEIndActivity.self).first()!)
    }
}
