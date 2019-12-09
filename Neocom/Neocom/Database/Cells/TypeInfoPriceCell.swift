//
//  TypeInfoPriceCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/9/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TypeInfoPriceCell: View {
    var price: Double
    var body: some View {
        HStack {
            Icon(Image("priceTotal"))
            VStack(alignment: .leading) {
                Text("PRICE").font(.footnote)
                Text(UnitFormatter.localizedString(from: price, unit: .isk, style: .long)).font(.footnote).foregroundColor(.secondary)
            }
        }
    }
}

struct TypeInfoPriceCell_Previews: PreviewProvider {
    static var previews: some View {
        TypeInfoPriceCell(price: 1e10)
    }
}
