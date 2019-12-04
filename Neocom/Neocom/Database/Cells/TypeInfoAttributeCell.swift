//
//  TypeInfoAttributeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/3/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible

extension TypeInfoData.Row {
    var attribute: Attribute? {
        switch self {
        case let .attribute(attribute):
            return attribute
        default:
            return nil
        }
    }
}

struct TypeInfoAttributeCell: View {
    var attribute: TypeInfoData.Row.Attribute
    @Environment(\.managedObjectContext) var managedObjectContext
    
    private var content: some View {
        HStack {
            attribute.image.map{Icon(Image(uiImage: $0))}
            VStack(alignment: .leading) {
                Text(attribute.title.uppercased()).font(.footnote)
                Text(attribute.subtitle).font(.footnote).foregroundColor(.secondary)
            }
        }
    }

    var body: some View {
        Group {
            if attribute.targetType != nil {
                NavigationLink(destination: TypeInfo(type: managedObjectContext.object(with: attribute.targetType!) as! SDEInvType)) { content }
            }
            else if attribute.targetGroup != nil {
                NavigationLink(destination: Types(predicate: \SDEInvType.group == managedObjectContext.object(with: attribute.targetGroup!) as! SDEInvGroup).navigationBarTitle(attribute.subtitle)) { content }
            }
            else {
                content
            }
        }
    }
}

struct TypeInfoAttributeCell_Previews: PreviewProvider {
    static var previews: some View {
        var attributes = (try? AppDelegate.sharedDelegate.testingContainer.viewContext.fetch(SDEInvType.dominix()).first?.attributes?.allObjects as? [SDEDgmTypeAttribute]) ?? []
        attributes.sort{$0.attributeType!.attributeName! < $1.attributeType!.attributeName!}
        return NavigationView {
            List(attributes.map{TypeInfoData.Row($0)}) { row in
                TypeInfoAttributeCell(attribute: row.attribute!)
            }.listStyle(GroupedListStyle())
        }
    }
}
