//
//  TypeInfoVariationsCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/5/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

extension TypeInfoData.Row {
    var variations: (Variations)? {
        switch self {
        case let .variations(variations):
            return variations
        default:
            return nil
        }
    }
}

struct TypeInfoVariationsCell: View {
    var variations: TypeInfoData.Row.Variations
    
    var body: some View {
        NavigationLink(destination: Types(.predicate(variations.predicate, NSLocalizedString("Variations", comment: "")))) {
            Text("\(variations.count) TYPES").font(.footnote)
        }
    }
}

struct TypeInfoVariationsCell_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                TypeInfoVariationsCell(variations: TypeInfoData.Row.Variations(count: 3, predicate: false))
            }.listStyle(GroupedListStyle())
        }
    }
}
