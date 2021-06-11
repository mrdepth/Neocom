//
//  LoyaltyOffers.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire

struct LoyaltyOffers: View {
    var corporationID: Int
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var loyaltyOffers = Lazy<LoyaltyOffersLoader, Never>()

    var body: some View {
        
        let result = sharedState.account.map { account in
            self.loyaltyOffers.get(initial: LoyaltyOffersLoader(esi: sharedState.esi, corporationID: Int64(corporationID), managedObjectContext: managedObjectContext))
        }
        let loyaltyOffers = result?.result?.value
        let error = result?.result?.error
        return Group {
            if loyaltyOffers != nil {
                LoyaltyOffersCategories(categories: loyaltyOffers!)
            }
            else {
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            }
        }
        .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
        .overlay(error.map{Text($0)})
        .overlay(loyaltyOffers?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
    }
}

struct LoyaltyOffersCategories: View {
    var categories: [LoyaltyOffersLoader.Category]
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        List(categories) { category in
            NavigationLink(destination: LoyaltyOffersGroups(category: category)) {
                CategoryCell(category: self.managedObjectContext.object(with: category.id) as! SDEInvCategory)
            }
        }.listStyle(GroupedListStyle())
    }
}

struct LoyaltyOffersGroups: View {
    var category: LoyaltyOffersLoader.Category
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        List(category.groups) { group in
            NavigationLink(destination: LoyaltyOffersTypes(group: group)) {
                GroupCell(group: self.managedObjectContext.object(with: group.id) as! SDEInvGroup)
            }
        }.listStyle(GroupedListStyle())
            .navigationBarTitle(category.name)
    }
}

struct LoyaltyOffersTypes: View {
    var group: LoyaltyOffersLoader.Category.Group
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        List(group.types) { type in
            NavigationLink(destination: TypeInfo(type: self.managedObjectContext.object(with: type.id) as! SDEInvType)) {
                VStack(alignment: .leading) {
                    TypeCell(type: self.managedObjectContext.object(with: type.id) as! SDEInvType)
                    VStack(alignment: .leading, spacing: 2) {
                        if type.offer.quantity > 1 {
                            HStack {
                                Text("Quantity:")
                                Text(UnitFormatter.localizedString(from: type.offer.quantity, unit: .none, style: .long))
                            }
                        }
                        HStack {
                            Text("Cost:")
                            Text(UnitFormatter.localizedString(from: type.offer.lpCost, unit: .loyaltyPoints, style: .long))
                            if type.offer.iskCost > 0 {
                                Text(UnitFormatter.localizedString(from: type.offer.iskCost, unit: .isk, style: .long))
                            }
                        }
                        ForEach(type.offer.requiredItems, id: \.typeID) {
                            LoyaltyOfferRequirement(requirement: $0)
                        }
                    }.modifier(SecondaryLabelModifier())
                }
            }.buttonStyle(PlainButtonStyle())
        }.listStyle(GroupedListStyle())
            .navigationBarTitle(group.name)
    }
}

#if DEBUG
struct LoyaltyOffers_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LoyaltyOffers(corporationID: 1000049)
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
