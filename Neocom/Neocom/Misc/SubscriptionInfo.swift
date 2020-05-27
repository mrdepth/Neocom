//
//  SubscriptionInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/25/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import ASReceipt
import StoreKit

struct SubscriptionInfo: View {
    var purchase: Receipt.Purchase
    var product: SKProduct?
    
    private var plan: some View {
        let period = product?.subscriptionPeriod?.localizedDescription
        let price = product.flatMap{$0.priceFormatter.string(from: $0.price)}
        return Group {
            if period != nil && price != nil {
                Text("\(price!) per \(period!)", comment: "price per period")
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image("logo").resizable().frame(width: 64, height: 64).cornerRadius(8)
            VStack(alignment: .leading) {
                Text("Remove Ads Subscription")
                if Config.current.inApps.lifetimeSubscriptions.contains(purchase.productID ?? "") {
                    Text("Lifetime").font(.caption)
                    Text("Remember to cancel any auto-renewable subscriptions.").modifier(SecondaryLabelModifier())
                }
                else {
                    plan.font(.caption)
                    if purchase.isExpired {
                        Text("Expired").modifier(SecondaryLabelModifier())
                    }
                    else {
                        purchase.expiresDate.map {
                            Text("Expires \(DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none))").modifier(SecondaryLabelModifier())
                        }
                    }
                }
            }
        }
    }
}

struct SubscriptionInfo_Previews: PreviewProvider {
    static var previews: some View {
        let data = NSDataAsset(name: "sandboxReceipt")?.data
        let receipt = try! Receipt(data: data!)
        return List {
            SubscriptionInfo(purchase: receipt.inAppPurchases!.first!, product: nil)
        }.listStyle(GroupedListStyle())
    }
}
