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
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account
    @ObservedObject private var loyaltyPoints = Lazy<LoyaltyPointsLoader>()

    var body: some View {
        let result = account.map { account in
            self.loyaltyPoints.get(initial: LoyaltyPointsLoader(esi: esi, characterID: account.characterID, managedObjectContext: managedObjectContext))
            }
        let loyaltyPoints = result?.result?.value?.loyaltyPoints
        let contacts = result?.result?.value?.contacts
        let error = result?.result?.error

        return List {
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
            .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay(error.map{Text($0)})
            .overlay(loyaltyPoints?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
            .navigationBarTitle(Text("Loyalty Points"))
    }
}

struct LoyaltyPoints_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return NavigationView {
            LoyaltyPoints()
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.account, account)
            .environment(\.esi, esi)
    }
}
