//
//  LifetimeSubscriptionInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/28/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct LifetimeSubscriptionInfo: View {
    var body: some View {
        HStack(spacing: 10) {
            Image("logo").resizable().frame(width: 64, height: 64).cornerRadius(8)
            VStack(alignment: .leading) {
                Text("Remove Ads Subscription")
                Text("Lifetime").font(.caption)
                Text("Remember to cancel any auto-renewable subscriptions.").modifier(SecondaryLabelModifier())
            }
        }
    }
}

struct LifetimeSubscriptionInfo_Previews: PreviewProvider {
    static var previews: some View {
        LifetimeSubscriptionInfo()
    }
}
