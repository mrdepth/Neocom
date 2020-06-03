//
//  ProductCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
import SwiftUI
import StoreKit

struct ProductCell: View {
    var product: SKProduct
    var isSelected: Bool
    
    private func localizedPrice() -> Text {
        let formatter = product.priceFormatter
        return Text(formatter.string(from: product.price) ?? "")
    }
    
    var body: some View {
        let period = product.subscriptionPeriod
        return HStack {
            if period != nil {
                VStack(alignment: .leading) {
                    Text(period!.localizedDescription.capitalized).accentColor(.primary)
                    Text("Auto-renewable subscription").modifier(SecondaryLabelModifier())
                }
            }
            else {
                VStack(alignment: .leading) {
                    Text("Lifetime").accentColor(.primary)
                    Text("One-time purchase").modifier(SecondaryLabelModifier())
                }
            }
            Spacer()
            localizedPrice().accentColor(.primary)
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
}
#endif
