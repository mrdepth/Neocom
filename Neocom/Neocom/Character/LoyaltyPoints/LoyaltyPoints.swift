//
//  LoyaltyPoints.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire

struct LoyaltyPoints: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var loyaltyPoints = Lazy<LoyaltyPointsLoader, Account>()

    var body: some View {
        let result = sharedState.account.map { account in
            self.loyaltyPoints.get(account, initial: LoyaltyPointsLoader(esi: sharedState.esi, characterID: account.characterID, managedObjectContext: managedObjectContext))
            }
        let loyaltyPoints = result?.result?.value?.loyaltyPoints
        let contacts = result?.result?.value?.contacts
        let error = result?.result?.error

        let list = List {
            if loyaltyPoints != nil && contacts != nil {
                ForEach(loyaltyPoints!, id: \.corporationID) { lp in
                    NavigationLink(destination: LoyaltyOffers(corporationID: lp.corporationID).navigationBarTitle((contacts![Int64(lp.corporationID)]?.name) ?? "")) {
                        HStack {
                            Avatar(corporationID: Int64(lp.corporationID), size: .size128).frame(width: 40, height: 40)
                            VStack(alignment: .leading) {
                                (contacts![Int64(lp.corporationID)]?.name).map{Text($0)} ?? Text("Unknown")
                                Text(UnitFormatter.localizedString(from: lp.loyaltyPoints, unit: .none, style: .long)).modifier(SecondaryLabelModifier())
                            }
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
            
        return Group {
            if result != nil {
                list.onRefresh(isRefreshing: Binding(result!, keyPath: \.isLoading), onRefresh: {
                    result?.update(cachePolicy: .reloadIgnoringLocalCacheData)
                })
            }
            else {
                list
            }
        }
        .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
        .overlay(error.map{Text($0)})
        .overlay(loyaltyPoints?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        .navigationBarTitle(Text("Loyalty Points"))
    }
}

#if DEBUG
struct LoyaltyPoints_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LoyaltyPoints()
        }.environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
            .environmentObject(SharedState.testState())
    }
}
#endif
