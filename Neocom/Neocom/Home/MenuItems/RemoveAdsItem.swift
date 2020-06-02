//
//  RemoveAdsItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/25/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
import SwiftUI

struct RemoveAdsItem: View {
    var body: some View {
        NavigationLink(destination: ProSubscription()) {
            Icon(Image("votes"))
            Text("Remove Ads")
        }
    }
}

struct RemoveAdsItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                RemoveAdsItem()
            }.listStyle(GroupedListStyle())
        }
    }
}
#endif
