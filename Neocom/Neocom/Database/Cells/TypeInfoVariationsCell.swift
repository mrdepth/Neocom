//
//  TypeInfoVariationsCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/5/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct TypeInfoVariationsCell: View {
    var type: SDEInvType
    
    var body: some View {
        let n = max(type.variations?.count ?? 0, type.parentType?.variations?.count ?? 0) + 1
        let what = type.parentType ?? type
        let predicate = /\SDEInvType.parentType == what || /\SDEInvType.self == what
        
        return NavigationLink(destination: Types(.predicate(predicate, NSLocalizedString("Variations", comment: "")))) {
            Text("Browse \(n) Variations")
        }
    }
}

struct TypeInfoVariationsCell_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                TypeInfoVariationsCell(type: .dominix)
            }.listStyle(GroupedListStyle())
        }
    }
}
